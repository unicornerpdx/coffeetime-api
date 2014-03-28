class App < Jsonatra::Base

  post '/device/register' do
    param_error :uuid, 'missing', 'uuid required' if params['uuid'].blank?
    param_error :token, 'missing', 'token is required' if params['token'].blank?
    param_error :token_type, 'missing', 'token_type is required (apns_production, apns_sandbox, gcm)' if params['token_type'].blank?
    param_error :token_type, 'invalid', 'token_type must be apns_production, apns_sandbox, or gcm' if !['apns_production','apns_sandbox','gcm'].include?(params['token_type'])
    halt if response.error?

    # TODO: actually store this somewhere

    {
      result: 'ok'
    }
  end

end
