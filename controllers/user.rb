class App < Jsonatra::Base

  get '/user/info' do
    require_auth
    
    if params['user_id'].blank?
      params['user_id'] = @token['user_id']
    end

    user = SQL[:users].first :id => params['user_id']
    param_error :user_id, 'invalid', 'user_id not found' if user.nil?

    halt if response.error?

    # If group_id is given, then return the user's balance in that group
    if params['group_id']
      group = SQL[:groups].first :id => params['group_id']
      param_error :group_id, 'not_found', 'group_id not found' if group.nil?

      halt if response.error?

      # Check the memberships table and error if there is no membership.
      # Memberships are never removed from the table, just marked as inactive later.
      membership = SQL[:memberships].first :group_id => group[:id], :user_id => user[:id]
      param_error :group_id, 'invalid', 'This user was never part of this group' if membership.nil?

      halt if response.error?
    else 
      group = nil
      membership = nil
    end

    format_user user, group, membership
  end

end
