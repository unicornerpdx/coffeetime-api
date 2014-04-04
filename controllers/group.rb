class App < Jsonatra::Base

  get '/group/list' do
    require_auth

    # Fetch new group list for the auth'd user

    {
      groups: [
        {
          group_id: 1,
          group_name: "Esri PDX",
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
      group_name: "Esri PDX",
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

  post '/group/create' do
    require_auth
    param_error :github_team_id, 'missing', 'github_team_id is required' if params['github_team_id'].blank?
    param_error :name, 'missing', 'name is required' if params['name'].blank?

    # Check if the user is a member of the team
    if !@github.team_member?(params['github_team_id'], @user[:username])
      param_error :github_team_id, 'invalid', 'You are not a member of this team'
    end

    # Check if the group already exists
    group = SQL[:groups].first :github_team_id => params['github_team_id']

    if group
      param_error :github_team_id, 'already_exists', 'There is already a group for this Github team!'
    end

    halt if response.error?

    # Let's go set up the group now!

    # Create the group
    SQL[:groups] << {
      github_team_id: params['github_team_id'],
      name: params['name'],
      date_updated: DateTime.now,
      date_created: DateTime.now
    }

    group = SQL[:groups].first :github_team_id => params['github_team_id']

    # Find all users in the team
    members = @github.team_members params['github_team_id']

    members.each do |member|
      user = SQL[:users].first :github_user_id => member.id.to_s
      if !user
        # Create user records for any users not already in the database
        SQL[:users] << {
          github_user_id: member.id.to_s,
          username: member.login,
          display_name: member.login,
          avatar_url: member.rels[:avatar].href,
          date_updated: DateTime.now,
          date_created: DateTime.now
        }
        user = SQL[:users].first :github_user_id => member.id.to_s
      end
      # Add the members to the group
      SQL[:memberships] << {
        group_id: group[:id],
        user_id: user[:id],
        balance: 0,
        active: true,
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
    end

    {
      group_id: group[:id],
      group_name: group[:name]
    }
  end

  post '/group/update' do

  end

  get '/team/list' do
    require_auth

    github_teams = @github.user_teams :per_page => 100

    teams = []
    github_teams.each do |team|
      teams << {
        github_id: team.id,
        name: team.name,
        org: team.organization.login,
        members: team.members_count
      }
    end

    {
      teams: teams,
      number: teams.length
    }
  end

end
