class App < Jsonatra::Base

  post '/callback/create' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    halt if response.error?

    # Check if it already exists
    callback = SQL[:callbacks].where(:group_id => @group[:id], :url => params['url']).first
    if callback and callback[:active]
      param_error :url, 'already_active', 'callback URL is already active'
    end

    halt if response.error?

    if callback
      SQL[:callbacks].where(:id => callback[:id]).update({
        active: true,
        date_updated: DateTime.now
      })
    else
      SQL[:callbacks] << {
        group_id: @group[:id],
        url: params['url'],
        active: true,
        date_created: DateTime.now,
        date_updated: DateTime.now
      }
    end

    {
      status: "ok"
    }
  end

  post '/callback/remove' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    halt if response.error?

    callback = SQL[:callbacks].where(:group_id => @group[:id], :url => params['url']).first
    if !callback or callback[:active] == false
      param_error :url, 'not_registered', 'url was not registered'
    end

    halt if response.error?

    SQL[:callbacks].where(:id => callback[:id]).update({
      active: false,
      date_updated: DateTime.now
    })

    {
      status: "ok"
    }
  end

  get '/callback/list' do
    require_auth
    require_group

    callbacks = SQL[:callbacks].where(:group_id => @group[:id], :active => true)

    {
      callbacks: callbacks.map{|cb|
        {
          url: cb[:url],
          last_request_date: format_date(cb[:last_payload_sent_date], @group[:timezone]),
          last_response_date: format_date(cb[:last_response_received_date], @group[:timezone]),
          last_response_status: cb[:last_response_status],
          last_response_status_code: cb[:last_response_code]
        }
      }
    }
  end

  get '/callback/status' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    halt if response.error?

    callback = SQL[:callbacks].where(:group_id => @group[:id], :url => params['url']).first
    if !callback or callback[:active] == false
      param_error :url, 'not_registered', 'url was not registered'
    end

    halt if response.error?

    {
      url: callback[:url],
      last_request_date: format_date(callback[:last_payload_sent_date], @group[:timezone]),
      last_response_date: format_date(callback[:last_response_received_date], @group[:timezone]),
      last_response_status: callback[:last_response_status],
      last_response_status_code: callback[:last_response_code],
      request: callback[:last_payload_sent],
      response: callback[:last_response_received]
    }
  end

end
