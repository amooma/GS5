class FreeswitchEventSocket
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 8021
  DEFAULT_PASSWORD = "ClueCon"
  DEFAULT_SOCKET_TIMEOUT = 20
  @socket = nil
  
  def auth(password)
    self.command("auth #{password}")
    result = self.result()

    if result && result["Reply-Text"] == "+OK accepted"
      return true
    end
    return false
  end

  def connect(password = nil, event_host = nil, event_port = nil)
    event_host = event_host || GsParameter.get('host', 'event_socket', 'client') || GsParameter.get('listen-ip', 'event_socket', 'settings') || DEFAULT_HOST
    event_port = event_port || GsParameter.get('port', 'event_socket', 'client') || GsParameter.get('listen-port', 'event_socket', 'settings') || DEFAULT_PORT
    password = password || GsParameter.get('password', 'event_socket', 'client') || GsParameter.get('password', 'event_socket', 'settings') || DEFAULT_PASSWORD

    begin
      @socket = TCPSocket.open(event_host, event_port)
    rescue
      return false
    end

    if not @socket
      return false
    end

    result = self.result()
    if result && result["Content-Type"] == "auth/request" then
      if not self.auth(password)
        return false
      end
    end

    return true
  end

  def command(command)
    @socket.puts("#{command}\n\n")
  end

  def close()
    @socket.close
  end

  def read(read_bytes=1024)
    return @socket.recv(read_bytes)
  end

  def result()
    reply = self.read()
    if reply.class == String
      message = Hash.new()
      header, body = reply.split("\n\n", 2)
      if ! body.blank?
        message['_BODY'] = body
      end
      header.split("\n").each do |line|
        key, value = line.split(/\: */, 2)
        message[key] = value
      end
      return message
    end
    return nil
  end
end

class FreeswitchEvent
  def initialize(event_type)
    @event_type = event_type
    @event_header = Array.new()
    @event_body = nil
    @event_header.push("sendevent #{@event_type}")
  end

  def add_header(name, value)
    @event_header.push("#{name}: #{value}")
  end

  def add_body(body)
    @event_body = body
  end

  def fire()
    if @event_body && @event_body.length > 0 
      self.add_header("content-length",  @event_body.length);
    end

    event = FreeswitchEventSocket.new()
    if event && event.connect()
      event.command(@event_header.join("\n"))
      event.command( @event_body)
      result = event.result()
      event.close()

      if result && result["Reply-Text"] == "+OK"
        return true
      end
    end
    return false
  end
end

class FreeswitchAPI
  def self.api_result(result)
    if not result
      return nil
    end

    if result['Content-Type'] == 'api/response'
      if result['_BODY'].blank?
        return nil
      elsif result['_BODY'] =~ /^\+OK/
        return true
      elsif result['_BODY'] =~ /^\-ERR/
        return false
      else
        return result['_BODY']
      end
    end
    
    return nil
  end

  def self.api(command, *arguments)
    event = FreeswitchEventSocket.new()
    if event && event.connect()
      event.command("api #{command} #{arguments.join(' ')}")
      result = event.result()
      content_length = result['Content-Length'].to_i
      while content_length > result['_BODY'].to_s.length
        body = event.read(content_length - result['_BODY'].to_s.length)
        if body.blank?
          break
        end
        result['_BODY'] = result['_BODY'].to_s + body;
      end
      event.close()
      return result
    end
  end

  def self.execute(command, arguments, bgapi = false)
    event = FreeswitchEventSocket.new()
    if event && event.connect()
      api = bgapi ? 'bgapi' : 'api'
      event.command( "#{api} #{command} #{arguments}")
      result = event.result()
      if result && result["Content-Type"] == 'api/response' && result["_BODY"].blank?
        result = event.result()
      end
      event.close()

      if result 
        if result.has_key?('Reply-Text') && result['Reply-Text'] =~ /^\+OK/
          if result.has_key?('Job-UUID') && ! result['Job-UUID'].blank?
            return result['Job-UUID'];
          else
            return true;
          end
        elsif result.has_key?('_BODY') && result['_BODY'] =~ /^\+OK/
          return true;
        end
      end
    end

    return false
  end

  def self.channel_variable_get(channel_uuid, variable_name)
    result = nil
    event = FreeswitchEventSocket.new()
    if event && event.connect()
      event.command( "api uuid_getvar #{channel_uuid} #{variable_name}")
      event_result = event.result()
      if event_result && event_result["Content-Type"] == 'api/response' && event_result["Content-Length"].to_i > 0
        result = event.read(event_result["Content-Length"].to_i)
      end
      event.close()
    end

    return result
  end

end
