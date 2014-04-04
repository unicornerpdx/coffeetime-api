class App < Jsonatra::Base

  post '/transaction/create' do
    require_auth
    require_group

    param_error :user_id, 'missing', 'user_id required' if params['user_id'].blank?

    other_user = SQL[:users].where(:id => params['user_id']).first
    param_error :user_id, 'invalid', 'user_id not found' if other_user.nil?
    halt if response.error?

    membership = SQL[:memberships].where(:user_id => other_user[:id], :group_id => @group[:id], :active => true).first
    param_error :user_id, 'invalid', 'user_id is not an active member of this group' if membership.nil?
    halt if response.error?

    param_error :amount, 'missing', 'amount is required' if params['amount'].blank? or params['amount'] == 0
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
      to_user_id = @user[:id]
    else
      # Screen is green
      # "Jane owes you 10 coffees"
      # App sends 10 and Jane's ID
      # Then says You bought Jane 10 coffees
      # Your balance goes up by 10 (@user += amount) (because amount is positive)
      # Jane's balance goes down by 10 (other_user -= amount) 
      from_user_id = @user[:id]
      to_user_id = other_user[:id]
    end

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
      SQL[:transactions] << {
        date: DateTime.now,
        group_id: @group[:id],
        created_by: @user[:id],
        from_user_id: from_user_id,
        to_user_id: to_user_id,
        amount: amount,
        note: params['note'],
        date_updated: DateTime.now,
        date_created: DateTime.now
      }.merge(location)
      # Update the balances for the two users
      SQL[:memberships].where(:group_id => @group[:id], :user_id => @user[:id]).update(:balance => Sequel.+(:balance, amount))
      SQL[:memberships].where(:group_id => @group[:id], :user_id => other_user[:id]).update(:balance => Sequel.-(:balance, amount))
    end

    {
      # see group/info
    }
  end

  get '/transaction/history' do
    require_auth
    require_group

    # from_id
    # to_id
    # limit

    {
      transactions: [

      ]
    }
  end

end
