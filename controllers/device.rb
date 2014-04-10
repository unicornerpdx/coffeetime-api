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
      puts "Device with this UUID already exists: #{params['uuid']} (User #{@user[:id]})"
      SQL[:devices].where(:id => device[:id]).update({
        token: params['token'],
        token_type: params['token_type'],
        active: true,
        date_updated: DateTime.now
      })
      device_id = device[:id]
    else
      puts "Creating a new device with UUID: #{params['uuid']} (User #{@user[:id]})"
      device_id = SQL[:devices].insert({
        user_id: @user[:id],
        uuid: params['uuid'],
        token: params['token'],
        token_type: params['token_type'],
        active: true,
        date_updated: DateTime.now,
        date_created: DateTime.now
      })
    end

    # Find any devices with the same UUID and mark all others as inactive
    SQL[:devices].where(:token => params['token']).exclude(:id => device_id).update(:active => false)

    {
      status: 'ok'
    }
  end

end
