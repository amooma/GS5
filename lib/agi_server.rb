module AGIServer
  DEFAULT_AGI_SERVER_HOST = nil
  DEFAULT_AGI_SERVER_PORT = 4573

  def self.log_debug(message)
      puts "DEBUG-AGI-Server: #{message.to_s}"
      #Rails.logger.debug "AGI-Server: #{message}"
  end

  def self.log_error(message)
      puts "ERROR-AGI-Server: #{message.to_s}"
      #Rails.logger.error "AGI-Server: #{message}"
  end

  class Client
    AGI_AVAILABLE_METHODS = ['directory_lookup']
    @client  = nil
    @options = nil

    def set_variable(variable_name, variable_value)
      if !@client
        return false
      end
      @client.puts "SET VARIABLE #{variable_name.to_s} \"#{variable_value.to_s}\""
    end

    def directory_lookup
      number = @options['agi_arg_1'].to_s.gsub(/[^0-9A-Za-z\*_-]/, '')
      number_type = @options['agi_arg_3'].to_s
      client_id = @options['agi_arg_2'].to_i

      if number.blank?
        number = @options['agi_dnid'].to_s.gsub(/[^0-9A-Za-z\*_-]/, '')
        number_type = "unknown"
        client_id = 1
      end

      if client_id > 0
        if number != ""
          phone_number = PhoneNumber.where(:number => number, :phone_numberable_type => "SipAccount").first
          if phone_number.blank?
            set_variable(:directory_status, 'unknown')
            set_variable(:directory_message, 'Number not found in directory')
            return nil
          end

          set_variable(:directory_status, 'exact_match')
          set_variable(:directory_message, 'Exact match')
          set_variable(:directory_number_type, phone_number.phone_numberable_type)
          set_variable(:directory_number_destination, phone_number.phone_numberable.to_s)
          set_variable(:directory_number_host, "1")
          set_variable(:directory_number_name, phone_number.name)
          set_variable(:directory_number_number, phone_number.number)
          set_variable(:directory_number_country_code, phone_number.country_code)
          set_variable(:directory_number_area_code, phone_number.area_code)
          set_variable(:directory_number_central_office_code, phone_number.central_office_code)
          set_variable(:directory_number_subscriber_number, phone_number.subscriber_number)
          set_variable(:directory_number_extension, phone_number.extension)

          if phone_number.phone_numberable_type == "SipAccount"
            set_variable(:directory_caller_name, phone_number.phone_numberable.caller_name)             
          end
        else
          set_variable(:directory_status, 'error')
          set_variable(:directory_message, 'No number specified')
        end
      else
        set_variable(:directory_status, 'error')
        set_variable(:directory_message, 'No ID')
      end
    end

    def handler(client)
      @client = client
      @options = Hash.new
      while @client
        buffer = @client.gets().strip
        if buffer == ""
          if @options['agi_network_script'] && AGI_AVAILABLE_METHODS.include?(@options['agi_network_script'].to_s.downcase)
            self.send(@options['agi_network_script'].to_s.downcase)
          end
          break
        elsif buffer =~ /^.*:\s/
          key, value = buffer.split(': ')
          @options[key]= value
        end
      end
      @client.close
    end
  end

  def self.server( host = DEFAULT_AGI_SERVER_HOST, port = DEFAULT_AGI_SERVER_PORT )

    log_debug("Starting server process.")
    require 'socket'
    server = TCPServer.open(4573)
    if server
      run_server = true
    end

    client_handler_id = 0
    while run_server
      log_debug("Server listening on: #{server.local_address.ip_address}:#{server.local_address.ip_port}")
      
      Thread.start(server.accept) do |client|
        remote_ip   = client.remote_address.ip_address
        remote_port = client.remote_address.ip_port
        
        begin
          client_handler = Client.new
          client_handler_id = client_handler.object_id
          log_debug("[#{client_handler_id}] Connection opened: #{remote_ip}:#{remote_port}")
          client_handler.handler(client)
          log_debug("[#{client_handler_id}] Connection closed: #{remote_ip}:#{remote_port}")
        rescue => e
          log_error("[#{client_handler_id}] #{e.class.to_s}: #{e.to_s},  closing connection: #{remote_ip}:#{remote_port}")
        ensure
          client.close()
        end
      end
    end
  end
end
