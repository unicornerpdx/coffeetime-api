class App < Jsonatra::Base

  get '/user/info' do
    require_auth
    param_error :user_id, 'missing', 'user_id required' if params['user_id'].blank?

    user = nil
    param_error :user_id, 'invalid', 'user_id not found required' if user.nil?

    # If group_id is given, then return the user's balance in that group

    {
      user_id: 0,
      username: token[:username],
      display_name: 'Bob',
      avatar_url: 'http://gravatar.com/foo',
      user_balance: 0,  # if group_id is given
      active: true      # if group_id is given
    }
  end

end
