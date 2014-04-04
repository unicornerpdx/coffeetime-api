class App < Jsonatra::Base

  post '/device/register' do
    require_auth

    param_error :uuid, 'missing', 'uuid required' if params['uuid'].blank?
    param_error :token, 'missing', 'token is required' if params['token'].blank?
    param_error :token_type, 'missing', 'token_type is required (apns_production, apns_sandbox, gcm)' if params['token_type'].blank?
    param_error :token_type, 'invalid', 'token_type must be apns_production, apns_sandbox, or gcm' if !['apns_production','apns_sandbox','gcm'].include?(params['token_type'])
    halt if response.error?

    # Check if the device already exists (by uuid)
    device = SQL[:devices].first :uuid => params['uuid'], :user_id => @user[:id]

    if device
      SQL[:devices].where(:id => device[:id]).update({
        token: params['token'],
        token_type: params['token_type'],
        active: true,
        date_updated: DateTime.now
      })
    else
      SQL[:devices] << {
        user_id: @user[:id],
        uuid: params['uuid'],
        token: params['token'],
        token_type: params['token_type'],
        active: true,
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
    end

    {
      status: 'ok'
    }
  end

end
