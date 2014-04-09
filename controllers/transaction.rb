class App < Jsonatra::Base

  post '/transaction/create' do
    require_auth
    require_group

    param_error :user_id, 'missing', 'user_id required' if params['user_id'].blank?
    param_error :amount, 'missing', 'amount is required' if params['amount'].blank? or params['amount'] == 0

    other_user = SQL[:users].where(:id => params['user_id']).first
    param_error :user_id, 'invalid', 'user_id not found' if other_user.nil?
    halt if response.error?

    membership = SQL[:memberships].where(:user_id => other_user[:id], :group_id => @group[:id], :active => true).first
    param_error :user_id, 'invalid', 'user_id is not an active member of this group' if membership.nil?
    halt if response.error?

    param_error :latitude, 'invalid', 'latitude is out of range (must be -90 to 90)' if !params['latitude'].blank? and !(-90..90).include?(params['latitude'].to_i)
    param_error :longitude, 'invalid', 'longitude is out of range (must be -180 to 180)' if !params['longitude'].blank? and !(-180..180).include?(params['longitude'].to_i)
    param_error :accuracy, 'invalid', 'accuracy is out of range (must be greater than 0)' if !params['accuracy'].blank? and params['accuracy'].to_i < 0
    halt if response.error?

    amount = params['amount'].to_i

    if amount < 0
      # Screen is red
      # "You owe Jane 10 coffees"
      # App sends -10 and Jane's ID
      # Then says Jane bought you 10 coffees
      # Jane's balance goes up by 10 (other_user -= amount) (has 10 more coffee points)
      # Your balance goes down by 10 (@user += amount) (because amount is negative)
      from_user_id = other_user[:id]
      from_user = other_user
      to_user_id = @user[:id]
      to_user = @user
      # This is the notification text to send to the other user
      notification = "You bought #{@user[:display_name]} #{amount.abs} coffee#{amount.abs == 1 ? '' : 's'}"
      callback_text = "#{other_user[:display_name]} bought #{@user[:display_name]} #{amount.abs} coffee#{amount.abs == 1 ? '' : 's'}"
    else
      # Screen is green
      # "Jane owes you 10 coffees"
      # App sends 10 and Jane's ID
      # Then says You bought Jane 10 coffees
      # Your balance goes up by 10 (@user += amount) (because amount is positive)
      # Jane's balance goes down by 10 (other_user -= amount) 
      from_user_id = @user[:id]
      from_user = @user
      to_user_id = other_user[:id]
      to_user = other_user
      # This is the notification text to send to the other user
      notification = "#{@user[:display_name]} bought you #{amount.abs} coffee#{amount.abs == 1 ? '' : 's'}"
      callback_text = "#{@user[:display_name]} bought #{other_user[:display_name]} #{amount.abs} coffee#{amount.abs == 1 ? '' : 's'}"
    end

    transaction_id = false
    user_membership = nil
    other_user_membership = nil

    SQL.transaction do
      if params['latitude']
        location = {
          location: Sequel.function(:ST_SetSRID, Sequel.function(:ST_MakePoint, params['longitude'], params['latitude']), 4326),
          accuracy: params['accuracy'],
          location_date: params['location_date']
        }
      else
        location = {}
      end

      # Add the transaction
      transaction_id = SQL[:transactions].insert({
        date: DateTime.now,
        group_id: @group[:id],
        created_by: @user[:id],
        from_user_id: from_user_id,
        to_user_id: to_user_id,
        amount: amount.abs,
        note: params['note'],
        date_updated: DateTime.now,
        date_created: DateTime.now
      }.merge(location))
      puts transaction_id.inspect
      # Update the balances for the two users
      user_membership = get_membership(@group[:id], @user[:id])
      user_membership.update(:balance => Sequel.+(:balance, amount))
      other_user_membership = get_membership(@group[:id], other_user[:id])
      other_user_membership.update(:balance => Sequel.-(:balance, amount))
    end

    # Reload the membership to get the updated balance for the group
    @membership = get_membership(@group[:id], @user[:id]).first

    if transaction_id
      transaction_url = "coffeetime://transaction?group_id=#{@group[:id]}&transaction_id=#{transaction_id}"

      # Send the authenticating user a push with their updated balance but no message
      user_balance = user_membership.first[:balance]
      data = {
        :badge => (user_balance < 0 ? user_balance.abs : 0),
        :group_id => @group[:id],
        :transaction_id => transaction_id,
        :balance => user_balance
      }
      Pushie.send @user, nil, data

      # Send the other user a push notification with a message and their updated balance
      other_user_balance = other_user_membership.first[:balance]
      data = {
        :badge => (other_user_balance < 0 ? other_user_balance.abs : 0),
        :group_id => @group[:id],
        :transaction_id => transaction_id,
        :balance => user_balance
      }
      Pushie.send other_user, notification, data

      # Send to the callback URLs registered for this group
      callback_params = {}
      callback_params[:group] = {
        group_id: @group[:id],
        group_name: @group[:name],
        timezone: @group[:timezone]
      }
      callback_params[:transaction] = format_transaction(SQL[:transactions].first(:id => transaction_id), @group[:timezone], false)
      callback_params[:from_user] = format_user(from_user, @group, get_membership(@group[:id], from_user[:id]).first)
      callback_params[:to_user] = format_user(to_user, @group, get_membership(@group[:id], to_user[:id]).first)
      Callback.send @group, callback_params

      group_info @group, @user, @membership
    else
      {
        error: {
          type: 'unknown_error',
          message: 'There was an error creating the transaction'
        }
      }
    end
  end

  get '/transaction/history' do
    require_auth
    require_group

    transactions = get_transactions @group[:id], @group[:timezone]

    # from_id
    # to_id
    # limit

    {
      users: @users.values.map{|u| format_user(u, @group, get_membership(@group[:id], u[:id]).first)},
      transactions: transactions
    }
  end

end
