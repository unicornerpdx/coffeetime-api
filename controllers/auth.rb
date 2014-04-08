class App < Jsonatra::Base

  # The app launches a browser to this URL
  get '/auth' do
    redirect "https://github.com/login/oauth/authorize?scope=read:org&client_id=#{SiteConfig['github']['client_id']}&redirect_uri=#{SiteConfig['github']['redirect_uri']}"
  end

  # Github redirects the user back here after signing in, with an auth code.
  # This route should redirect the user back to the mobile app with the same auth code.
  get '/auth/callback' do
    redirect "coffeetime://auth?code=#{params['code']}"
  end

  # The app posts the auth code to here to get an access token
  post '/auth' do
    param_error :code, 'missing', 'code required' if params[:code].blank?
    halt if response.error?

    client = HTTPClient.new
    result = client.post "https://github.com/login/oauth/access_token", {
      :client_id => SiteConfig['github']['client_id'],
      :client_secret => SiteConfig['github']['client_secret'],
      :code => params[:code],
      :redirect_uri => SiteConfig['github']['redirect_uri']
    }, {
      'Accept' => 'application/json'
    }

    puts result.body

    param_error :github, 'bad_response', 'Bad response from Github API' if result.body.nil? 

    github_token = JSON.parse result.body

    param_error :github, 'bad_response', 'Github API did not return JSON' if github_token.nil?
    param_error :code, 'invalid_code', github_token['error_description'] if github_token['error_description']
    param_error :code, 'bad_response', 'Github API did not return an access token' if github_token['access_token'].nil?

    halt if response.error?

    # Look up the user profile from Github

    result = client.get "https://api.github.com/user", nil, {
      'Authorization' => "Bearer #{github_token['access_token']}"
    }
    github_user = JSON.parse result.body

    jj github_user

    # Check if the user already exists, and update if so
    user = SQL[:users].first :github_user_id => github_user['id'].to_s
    if user
      SQL[:users].where(:id => user[:id]).update({
        username: github_user['login'],
        display_name: github_user['login'],
        avatar_url: github_user['avatar_url'],
        date_updated: DateTime.now
      })
    else
      SQL[:users] << {
        github_user_id: github_user['id'].to_s,
        username: github_user['login'],
        display_name: github_user['login'],
        avatar_url: github_user['avatar_url'],
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
      user = SQL[:users].first :github_user_id => github_user['id'].to_s
    end

    token = {
      user_id: user[:id],
      username: user[:username],
      github_access_token: github_token['access_token'],
      date_issued: Time.now.to_i,
      nonce: SecureRandom.hex
    }

    {
      access_token: JWT.encode(token, SiteConfig['secret']),
      user_id: user[:id],
      username: user[:username],
      display_name: user[:display_name],
      avatar_url: user[:avatar_url]
    }
  end

  # For debugging, this lets clients generate access tokens for any user
  if ENV['RACK_ENV'] == 'development'
    post '/auth/assert' do
      param_error :user_id, 'missing', 'user_id required' if params['user_id'].blank?

      halt if response.error?

      user = SQL[:users].first :id => params['user_id']

      token = {
        user_id: user[:id],
        username: user[:username],
        github_access_token: nil,
        date_issued: Time.now.to_i,
        nonce: SecureRandom.hex
      }

      {
        access_token: JWT.encode(token, SiteConfig['secret']),
        user_id: user[:id],
        username: user[:username],
        display_name: user[:display_name],
        avatar_url: user[:avatar_url]
      }
    end
  end

end
