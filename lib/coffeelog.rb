class CoffeeLog

  @@log = Logger.new('log.txt')

  def debug(msg, req=nil, user=nil, group=nil)
    msg = "#{msg} [req:#{req}]" if req
    msg = "#{msg} [user:#{user[:id]}/#{user[:username]}]" if user
    msg = "#{msg} [group:#{group[:id]}/#{group[:name]}]" if group
    @@log.debug msg
  end

end