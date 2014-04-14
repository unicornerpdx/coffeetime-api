class App < Jsonatra::Base

  get '/group/list' do
    require_auth

    query = SQL[:groups].select(:groups__id, :groups__name, :memberships__balance).join(:memberships, :group_id => :id).where(:memberships__user_id => @user[:id])

    groups = query.map do |group|
      balance = group_balance(group[:id])
      {
        group_id: group[:id],
        group_name: group[:name],
        timezone: group[:timezone],
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
      GroupHelper.add_user_to_group_from_github member, group
    end

    {
      group_id: group[:id],
      group_name: group[:name],
      timezone: group[:timezone]
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

    result = GroupHelper.update_group_members_from_github @github, @group

    {
      group_id: @group[:id],
      group_name: @group[:name],
      timezone: @group[:timezone],
      users_added: result[:added],
      users_removed: result[:removed]
    }
  end

  get '/team/list' do
    require_auth

    github_teams = @github.user_teams :per_page => 100

    teams = github_teams.map do |team|
      {
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

  def group_info(group, user, membership=nil, transaction_list=false)
    membership = get_membership(group[:id], user[:id]).first if membership.nil? and !user.nil?
    balance = group_balance group[:id]
    recent_transactions = get_recent_transactions group[:id], user[:id], group[:timezone] if transaction_list == false

    if !transaction_list
      # Running get_recent_transactions sets the variable @users with any users that participated in the transaction even if they are inactive
      # Now we also need to include all active members of the group
      active_users = SQL[:users].select(Sequel.lit('users.*')).join(:memberships, :user_id => :id).where(:memberships__group_id => group[:id], :active => true)
      active_users.each do |u|
        @users[u[:id]] = u
      end
    end

    if membership
      m = {
        user_balance: membership[:balance]
      }
    else
      m = {}
    end

    {
      group_name: group[:name],
      timezone: group[:timezone],
      min_balance: balance[:min],
      max_balance: balance[:max],
      users: @users.values.map{|u| format_user(u, group, get_membership(group[:id], u[:id]).first)},
      transactions: (transaction_list ? transaction_list : recent_transactions)
    }.merge(m)
  end

end
