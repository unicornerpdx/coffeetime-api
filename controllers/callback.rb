class App < Jsonatra::Base

  post '/callback/register' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    halt if response.error?

    {
      status: "ok"
    }
  end

  post '/callback/remove' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    param_error :url, 'not_registered', 'url was not registered' if false

    halt if response.error?

    {
      status: "ok"
    }
  end

  get '/callback/list' do
    require_auth
    require_group

    {
      callbacks: [
        {
          url: "http://example.com/callback",
          last_request_date: "2014-03-27T13:49:00-0700",
          last_response_date: "2014-03-27T13:49:00-0700",
          response_status_code: 200
        }
      ]
    }
  end

  get '/callback/status' do
    require_auth
    require_group

    param_error :url, 'missing', 'url is required' if params['url'].blank?
    param_error :url, 'invalid', 'url is invalid' if false

    param_error :url, 'not_registered', 'url was not registered' if false

    halt if response.error?

    {
      url: "http://example.com/callback",
      last_request_date: "2014-03-27T13:49:00-0700",
      request: "POST /callback HTTP/1.1\nHost: example.com\nContent-type: application/json\n\n{.....}",
      last_response_date: "2014-03-27T13:49:00-0700",
      response_status_code: 200,
      response: "HTTP/1.1 200 OK\n\n"
    }
  end

end
