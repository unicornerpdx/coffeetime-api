class App < Jsonatra::Base

  post '/auth' do
    param_error :github_auth_code, 'missing', 'github_auth_code required' if params[:github_auth_code].blank?
    halt if response.error?

    client = HTTPClient.new
    result = client.post "https://github.com/login/oauth/access_token", {
      :client_id => SiteConfig['github']['client_id'],
      :client_secret => SiteConfig['github']['client_secret'],
      :code => params[:github_auth_code],
      :redirect_uri => SiteConfig['github']['redirect_uri']
    }, {
      'Accept' => 'application/json'
    }

    puts result.body

    param_error :github, 'bad_response', 'Bad response from Github API' if result.body.nil? 

    github_token = JSON.parse result.body

    param_error :github, 'bad_response', 'Github API did not return JSON' if github_token.nil?
    param_error :github_auth_code, 'invalid_code', github_token['error_description'] if github_token['error_description']
    param_error :github_auth_code, 'bad_response', 'Github API did not return an access token' if github_token['access_token'].nil?

    halt if response.error?

    # Look up the user profile from Github

    result = client.get "https://api.github.com/user", nil, {
      'Authorization' => "Bearer #{github_token['access_token']}"
    }
    github_user = JSON.parse result.body

    jj github_user


    token = {
      username: github_user['login'],
      github_access_token: github_token['access_token'],
      date_issued: Time.now.to_i,
      nonce: SecureRandom.hex
    }

    {
      access_token: JWT.encode(token, SiteConfig['secret']),
      user_id: 0,
      username: token[:username],
      display_name: github_user['name'],
      avatar_url: github_user['avatar_url']
    }
  end

end
