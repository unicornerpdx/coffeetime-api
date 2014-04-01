class App < Jsonatra::Base

  post '/transaction/create' do
    require_auth
    require_group

    param_error :user_id, 'missing', 'user_id required' if params['user_id'].blank?

    user = nil
    param_error :user_id, 'invalid', 'user_id not found required' if user.nil?

    halt if response.error?

    param_error :user_id, 'invalid', 'user_id is not a member of this group' if false

    param_error :amount, 'missing', 'amount is required' if params['amount'].blank? or params['amount'] == 0

    halt if response.error?

    # note
    # latitude
    # longitude
    # accuracy
    # location_date

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
