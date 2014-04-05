Dir.glob(['controllers','lib'].map! {|d| File.join d, '*.rb'}).each do |f| 
  require_relative f
end

class App < Jsonatra::Base

  configure do
    set :arrayified_params, [:keys]    
  end

  def require_auth
    param_error :authorization, 'missing', 'Authorization header required' if request.env['HTTP_AUTHORIZATION'].nil? or request.env['HTTP_AUTHORIZATION'].empty?
    auth = request.env['HTTP_AUTHORIZATION'].match /Bearer (.+)/
    param_error :authorization, 'invalid', 'Bearer authorization header required' if auth.nil?
    access_token = auth[1]
    begin
      @token = JWT.decode(access_token, SiteConfig['secret'])
      puts "Auth: #{@token.inspect}"
    rescue 
      param_error :authorization, 'invalid', 'Access token was invalid'
    end
    halt if response.error?

    @github = Octokit::Client.new :access_token => @token['github_access_token']
    Octokit.auto_paginate = true

    @user = SQL[:users].first :id => @token['user_id']

    @token
  end

  def require_group
    param_error :group_id, 'missing', 'group_id required' if params['group_id'].blank?
    halt if response.error?

    # Check if the group exists
    @group = SQL[:groups].first :id => params['group_id']
    param_error :group_id, 'invalid', 'group_id not found' if @group.nil?
    halt if response.error?

    # Check if the user is a member of the group
    @membership = get_membership(@group[:id], @user[:id]).first
    param_error :group_id, 'forbidden', 'user not a member of this group' if @membership.nil?
    halt if response.error?

    # Cache users being returned in a list
    @users = {}
  end

  def timezone_from_param
    begin
      timezone = Timezone::Zone.new :zone => params['timezone']
    rescue Timezone::Error::InvalidZone
      param_error :timezone, 'invalid', 'Invalid timezone specified'
    end
  end

  def group_balance(group_id)
    SQL[:memberships].select(Sequel.function(:max, :balance), Sequel.function(:min, :balance)).where(:group_id => group_id).first
  end

  def get_membership(group_id, user_id) 
    SQL[:memberships].where(:group_id => group_id, :user_id => user_id)
  end

  def get_recent_transactions(group_id, user_id, tz)
    query = SQL[:transactions].select(Sequel.lit('*, ST_Y(location::geometry) AS latitude, ST_X(location::geometry) AS longitude'))
      .where(:group_id => group_id).where(Sequel.or(:from_user_id => user_id, :to_user_id => user_id)).order(:date)
    transactions = []
    query.each do |t|
      transactions << format_transaction(t, tz)
    end
    transactions
  end

  def format_date(date, tz)
    if date
      timezone = Timezone::Zone.new :zone => tz
      date.to_time.localtime(timezone.utc_offset).iso8601
    else
      nil
    end
  end

  def format_transaction(transaction, tz)
    if @users[transaction[:from_user_id]].nil?
      @users[transaction[:from_user_id]] = SQL[:users].first :id => transaction[:from_user_id]
    end
    if @users[transaction[:to_user_id]].nil?
      @users[transaction[:to_user_id]] = SQL[:users].first :id => transaction[:to_user_id]
    end

    from = @users[transaction[:from_user_id]]
    to = @users[transaction[:to_user_id]]

    summary = "#{from[:id] == @user[:id] ? 'You' : from[:display_name]} bought #{transaction[:amount]} coffees for #{to[:id] == @user[:id] ? 'you' : to[:display_name]}"

    {
      date: format_date(transaction[:date], tz),
      from_user_id: transaction[:from_user_id],
      to_user_id: transaction[:to_user_id],
      amount: transaction[:amount],
      note: transaction[:note],
      created_by: transaction[:created_by],
      latitude: transaction[:latitude],
      longitude: transaction[:longitude],
      accuracy: transaction[:accuracy],
      location_date: format_date(transaction[:location_date], tz),
      summary: summary
    }
  end

  get '/' do
    {
      hello: 'world'
    }
  end

end
