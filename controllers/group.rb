class App < Jsonatra::Base

  get '/group/list' do
    require_auth

    # Fetch new group list for the auth'd user

    {
      groups: [
        {
          group_id: 1,
          organization_name: "Esri PDX",
          user_balance: 10
        }
      ]
    }
  end

  get '/group/info' do
    require_auth
    require_group

    # TODO: get user balance for the group

    # TODO: get list of recent transactions the auth'd user has participated in the group

    {
      organization_name: "Esri PDX",
      user_balance: 10,
      users: [
        {
          user_id: 0,
          username: 'bob',
          display_name: 'Bob',
          avatar_url: 'http://gravatar.com/foo'
        }
      ],
      transactions: [
        {
          date: "2014-03-27T09:00:00-0700",
          from_user_id: 13,
          to_user_id: 14,
          latitude: 45,
          longitude: -122,
          accuracy: 1000,
          amount: 3,
          note: "Sucker",
          created_by: 13
        }
      ]
    }
  end

end
