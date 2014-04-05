class App < Jsonatra::Base

  get '/group/list' do
    require_auth

    query = SQL[:groups].select(:groups__id, :groups__name, :memberships__balance).join(:memberships, :group_id => :id).where(:memberships__user_id => @user[:id])

    groups = []
    query.each do |group|
      balance = group_balance(group[:id])
      groups << {
        group_id: group[:id],
        group_name: group[:name],
        user_balance: group[:balance],
        max_balance: balance[:max],
        min_balance: balance[:min]
      }
    end

    {
      groups: groups
    }
  end

  get '/group/info' do
    require_auth
    require_group
    group_info @group, @user, @balance
  end

  def add_user_to_group_from_github(member, group)
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
    # Add the member to the group if they are not already
    membership = get_membership(group[:id], user[:id]).first
    if !membership
      SQL[:memberships] << {
        group_id: group[:id],
        user_id: user[:id],
        balance: 0,
        active: true,
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
    else
      # Re-activate the user if there was already a membership for them
      if membership[:active] == false
        get_membership(group[:id], user[:id]).first.update(:active => true)
      end
    end
  end

  post '/group/create' do
    require_auth
    param_error :github_team_id, 'missing', 'github_team_id is required' if params['github_team_id'].blank?
    param_error :name, 'missing', 'name is required' if params['name'].blank?

    # Validate the timezone
    params['timezone'] = 'America/Los_Angeles' if params['timezone'].blank?
    timezone = timezone_from_param

    halt if response.error?

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
      timezone: timezone.zone,
      date_updated: DateTime.now,
      date_created: DateTime.now
    }

    group = SQL[:groups].first :github_team_id => params['github_team_id']

    # Find all members of the team
    members = @github.team_members params['github_team_id']

    members.each do |member|
      add_user_to_group_from_github member, group
    end

    {
      group_id: group[:id],
      group_name: group[:name],
      timezone: @group[:timezone]
    }
  end

  post '/group/update' do
    # Can be used to update the group name
    # Also updates the list of members in the group from the Github team
    require_auth
    require_group

    if !params['timezone'].blank?
      begin
        timezone = Timezone::Zone.new :zone => params['timezone']
      rescue Timezone::Error::InvalidZone
        param_error :timezone, 'invalid', 'Invalid timezone specified'
      end
    end

    # Update name or timezone
    if !params['timezone'].blank? or !params['name'].blank?
      update = {}
      update[:name] = params['name'] if !params['name'].blank?
      update[:timezone] = timezone.zone if !params['timezone'].blank?
      SQL[:groups].where(:id => @group[:id]).update(update)
      @group = SQL[:groups].first :id => @group[:id]
    end

    # Add any new people from the Github team
    github_member_ids = []
    members = @github.team_members @group[:github_team_id]
    members.each do |member|
      github_member_ids << member.id.to_s
      add_user_to_group_from_github member, @group
    end

    # Check existing member list and deactivate them if they are not in the Github team anymore
    members = SQL[:memberships].select(:memberships__id, :users__github_user_id).join(:users, :id => :user_id).where(:group_id => @group[:id])
    members.each do |member|
      if !github_member_ids.include? member[:github_user_id]
        SQL[:memberships].where(:id => member[:id]).update(:active => false)
      end
    end

    {
      group_id: @group[:id],
      group_name: @group[:name],
      timezone: @group[:timezone]
    }
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

  def group_info(group, user, membership=nil)
    membership = get_membership(group[:id], user[:id]).first if membership.nil?
    balance = group_balance group[:id]
    transactions = get_recent_transactions group[:id], user[:id], group[:timezone]

    {
      group_name: group[:name],
      user_balance: membership[:balance],
      min_balance: balance[:min],
      max_balance: balance[:max],
      users: [
        {
          user_id: 0,
          username: 'bob',
          display_name: 'Bob',
          avatar_url: 'http://gravatar.com/foo'
        }
      ],
      transactions: transactions
    }
  end

end
