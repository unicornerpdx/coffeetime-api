class App < Jsonatra::Base

  post '/auth' do
    param_error :github_auth_code, 'missing', 'github_auth_code required' if params[:github_auth_code].blank?
    halt if response.error?

    # TODO: exchange auth code at Github and set the username in the token appropriately

    token = {
      username: 'aaronpk',
      github_access_token: '',
      date_issued: Time.now.to_i,
      nonce: SecureRandom.hex
    }

    {
      access_token: JWT.encode(token, SiteConfig['secret'])
    }
  end

end
