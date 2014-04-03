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
    group = nil
    param_error :group_id, 'invalid', 'group_id not found required' if group.nil?
    # Check if the user is a member of the group
    param_error :group_id, 'forbidden', 'user not a member of this group' if false
    @group = nil
  end

  get '/' do
    {
      hello: 'world'
    }
  end

end
