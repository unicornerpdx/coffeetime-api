class Callback
  include Celluloid::IO

  def run(group, data)
    payload = Rack::Utils.build_nested_query(Callback.stringify_integers_deep!(data))

    callbacks = SQL[:callbacks].where(:group_id => group[:id], :active => true)
    callbacks.each do |callback|
      sent_date = DateTime.now
      begin
        result = HTTP.post callback[:url], body: payload, socket_class: Celluloid::IO::TCPSocket
        headers = result.headers.to_h
        SQL[:callbacks].where(:id => callback[:id]).update({
          last_payload_sent_date: sent_date,
          last_payload_sent: payload,
          last_response_received_date: DateTime.now,
          last_response_received: headers.keys.reduce(""){|s,k| s << "#{k}: #{headers[k]}\n"; s}+"\n"+result.body.to_s,
          last_response_code: result.code,
          last_response_status: (result.code == 200 ? 'ok' : 'error')
        })
      # rescue HTTPClient::TimeoutError
      #   SQL[:callbacks].where(:id => callback[:id]).update({
      #     last_payload_sent_date: sent_date,
      #     last_payload_sent: payload,
      #     last_response_status: 'timeout'
      #   })
      rescue
        SQL[:callbacks].where(:id => callback[:id]).update({
          last_payload_sent_date: sent_date,
          last_payload_sent: payload,
          last_response_status: 'error'
        })
      end
    end
  end

  # Fix for https://github.com/rack/rack/issues/557
  def self.stringify_integers_deep!(hash)
    hash.each do |key, value|
      hash[key] = value.to_s if value.kind_of?(Integer)
      Callback.stringify_integers_deep!(value) if value.kind_of?(Hash)
    end
  end

end