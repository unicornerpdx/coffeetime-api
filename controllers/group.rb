class App < Jsonatra::Base

  get '/group/list' do
    require_auth

    # Fetch new group list for the auth'd user

    {
      groups: []
    }
  end

  get '/group/info' do
    require_auth
    require_group

    # TODO: get user balance for the group

    # TODO: get list of recent transactions the auth'd user has participated in the group

    {
      user_balance: 0,
      users: [],
      transactions: []
    }
  end

end
