class ConfigPolycomController < ApplicationController
	MAX_SIP_ACCOUNTS_COUNT = 11
	MAX_SOFTKEYS_COUNT = 12
  MAX_DIRECTORY_ENTRIES = 20
  SIP_DEFAULT_PORT = 5060
 
	skip_authorization_check
	
	before_filter { |controller|
    if ! params[:mac_address].blank? then
      @mac_address = params[:mac_address].upcase.gsub(/[^0-9A-F]/,'')
      @phone = Phone.where({ :mac_address => @mac_address }).first
    elsif ! params[:phone].blank? then
      @phone = Phone.where({ :id => params[:phone].to_i }).first
    end      

    if ! @phone
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Phone not found -->",
      )
      return false
    end

    if ! params[:sip_account].blank?
      @sip_account = @phone.sip_accounts.where({ :id => params[:sip_account].to_i }).first
      if ! @sip_account && @phone.fallback_sip_account && @phone.fallback_sip_account.id == params[:sip_account].to_i
        @sip_account = @phone.fallback_sip_account
      end
      if ! @sip_account
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- SipAccount ID:#{params[:sip_account]} not found -->",
        )
        return false
      end
    end

    if ! params[:type].blank?
      @type = params[:type].to_s.strip.downcase
    end
	}
	
  def config_files
    if params[:mac_address].blank? then
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- MAC not specified -->",
      )
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render
      }
    }
  end
	
	def settings
		if ! request.env['HTTP_USER_AGENT'].index('polycom')
			Rails.logger.info "---> User-Agent indicates not a Polycom phone (#{request.env['HTTP_USER_AGENT'].inspect})"
		else
			Rails.logger.info "---> Phone #{@mac_address.inspect}, IP address #{request_remote_ip.inspect}"
			@phone.update_attributes({ :ip_address => request_remote_ip })
		end

    xml_applications_url = "#{request.protocol}#{request.host_with_port}/config_polycom/#{@phone.id}/0"

    @settings = {
      'device.sntp.serverName' => 'pool.ntp.org',
      'device.sntp.gmtOffset' => 3600,
      'up.welcomeSoundOnWarmBootEnabled' => 0,
      'up.welcomeSoundEnabled' => 0,
      'bg.hiRes.color.selection' => '2,1',
      'msg.mwi.1.callBackMode' => 'contact', 
      'msg.mwi.1.callBack' => 'f-vmcheck',
      'feature.enhancedFeatureKeys.enabled' => 1,
      'softkey.feature.basicCallManagement.redundant' => 0,
      'softkey.feature.buddies' => 0,
      'softkey.feature.callers' => 0,
      'softkey.feature.directories' => 0,
      'softkey.feature.endcall' => 1,
      'softkey.feature.forward' => 0,
      'softkey.feature.mystatus' => 0,
      'softkey.feature.newcall' => 0,
      'call.directedCallPickupMethod' => 'legacy',
      'call.directedCallPickupString' => 'f-ia-',
      'call.advancedMissedCalls.enabled' => 0,
      'lineKey.reassignment.enabled' => 1,
      'lineKey.1.category' => 'Line',
      'lineKey.1.index' => 1,
    }

    for key_index in 2..42
      @settings["lineKey.#{key_index}.category"] = 'Unassigned'
    end

    for ring_class in 1..17
      @settings["se.rt.custom#{ring_class}.name"] = "Ringer#{ring_class-1}"
      @settings["se.rt.custom#{ring_class}.ringer"] = "ringer#{ring_class}"
    end
    @settings["se.rt.custom1.type"] = 'visual'

    for ring_class in 1..17
      @settings["voIpProt.SIP.alertInfo.#{ring_class}.class"] = "custom#{ring_class}"
      @settings["voIpProt.SIP.alertInfo.#{ring_class}.value"] = "Ringer#{ring_class-1}"
    end

    softkey_index = 1
    blf_index = 0

    phone_sip_accounts = Array.new()
    if @phone.sip_accounts && @phone.sip_accounts.count > 0
      phone_sip_accounts = @phone.sip_accounts
    elsif @phone.fallback_sip_account
      phone_sip_accounts.push( @phone.fallback_sip_account )
    end
    sip_account_index = 0
    phone_sip_accounts.each do |sip_account|
      sip_account_index += 1
      if sip_account_index == 1
        xml_applications_url = "#{request.protocol}#{request.host_with_port}/config_polycom/#{@phone.id}/#{sip_account.id}"
        @settings['voIpProt.SIP.outboundProxy.address'] = sip_account.host
        @settings['voIpProt.SIP.outboundProxy.port'] = SIP_DEFAULT_PORT
      end

      @settings["reg.#{sip_account_index}.address"] = "#{sip_account.auth_name}@#{sip_account.host}"
      @settings["reg.#{sip_account_index}.auth.password"] = sip_account.password
      @settings["reg.#{sip_account_index}.auth.userId"] = sip_account.auth_name
      @settings["reg.#{sip_account_index}.displayName"] = 'Call'
      @settings["reg.#{sip_account_index}.label"] = sip_account.caller_name
      @settings["voIpProt.server.#{sip_account_index}.address"] = sip_account.host
      @settings["voIpProt.server.#{sip_account_index}.port"] = SIP_DEFAULT_PORT
      @settings["call.missedCallTracking.#{sip_account_index}.enabled"] = 0 

      sip_account.softkeys.order(:position).each do |softkey|
        softkey_index += 1
        if softkey.softkey_function
          softkey_function = softkey.softkey_function.name
        end
        case softkey_function
        when 'blf'
          blf_index += 1
          @settings["lineKey.#{softkey_index}.category"] = 'BLF'
          @settings["attendant.resourceList.#{blf_index}.address"] = "#{softkey.number}@#{sip_account.host}"
          @settings["attendant.resourceList.#{blf_index}.label"] = softkey.label
        end
      end
    end

    @settings['mb.idleDisplay.home'] = "#{xml_applications_url}/idle_screen.xml"
    @settings['mb.idleDisplay.refresh'] = 60

    @settings['efk.efklist.1.mname'] = "directory"
    @settings['efk.efklist.1.status'] = 1
    @settings['efk.efklist.1.action.string'] = "#{xml_applications_url}/phone_book.xml"
    @settings['efk.efklist.2.mname'] = "callhistory"
    @settings['efk.efklist.2.status'] = 1
    @settings['efk.efklist.2.action.string'] = "#{xml_applications_url}/call_history.xml"
    @settings['efk.efklist.3.mname'] = "applications"
    @settings['efk.efklist.3.status'] = 1
    @settings['efk.efklist.3.action.string'] = "#{xml_applications_url}/applications.xml"

    @settings['softkey.1.action'] = "#{xml_applications_url}/phone_book.xml"
    @settings['softkey.1.enable'] = 1
    @settings['softkey.1.insert'] =  1
    @settings['softkey.1.label'] = 'Directory'
    @settings['softkey.1.precede'] = 1
    @settings['softkey.1.use.active'] = 1
    @settings['softkey.1.use.alerting'] = 0
    @settings['softkey.1.use.dialtone'] = 1
    @settings['softkey.1.use.hold'] = 1
    @settings['softkey.1.use.idle'] = 1
    @settings['softkey.1.use.proceeding'] = 0
    @settings['softkey.1.use.setup'] = 0
    @settings['softkey.2.action'] = "#{xml_applications_url}/call_history.xml"
    @settings['softkey.2.enable'] = 1
    @settings['softkey.2.insert'] =  2
    @settings['softkey.2.label'] = 'Call History'
    @settings['softkey.2.precede'] = 1
    @settings['softkey.2.use.active'] = 1
    @settings['softkey.2.use.alerting'] = 0
    @settings['softkey.2.use.dialtone'] = 1
    @settings['softkey.2.use.hold'] = 1
    @settings['softkey.2.use.idle'] = 1
    @settings['softkey.2.use.proceeding'] = 0
    @settings['softkey.2.use.setup'] = 0

		respond_to { |format|
			format.any {
				self.formats = [ :xml ]
				render
			}
		}
	end


  def settings_directory
    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render
      }
    }
  end


  def call_history

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if ['dialed', 'missed', 'received'].include? @type
      @phone_xml_object = { 
        :name => "call_history",
        :title => @type.titleize,
        :entries => []
      }

      calls = @sip_account.call_histories.where(:entry_type => @type).order('start_stamp DESC').limit(MAX_DIRECTORY_ENTRIES)

      calls.each do |call|
        display_name = call.display_name
        phone_number = call.display_number
        phone_book_entry = call.phone_book_entry_by_number(phone_number)
        if display_name.blank?
          display_name = phone_book_entry.to_s
        end
        
        @phone_xml_object[:entries].push({
            :selected => false, 
            :number => phone_number,
            :date => call.start_stamp.strftime('%d.%m %H:%M'),
            :text => display_name,
            :url => "tel:#{phone_number}",
            })     
      end
    else
      base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"
      @phone_xml_object = { 
        :name => 'call_history_menu',
        :title => 'Call History Lists',
        :entries => [
          {:text => 'Missed Calls', :url => "#{base_url}?&type=missed",   :selected => false},
          {:text => 'Received Calls',  :url => "#{base_url}?&type=received", :selected => false},
          {:text => 'Placed Calls', :url => "#{base_url}?&type=dialed",   :selected => false},
        ]
      }
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}", :content_type => Mime::HTML
      }
    }

  end

  
  def phone_book

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    @phone_xml_object = { 
      :name => 'phone_book',
      :title => "Phone Book".strip,
      :entries => [],
      :softkeys => [],
    }

    phone_books = Array.new()
    phone_books = phone_books + @sip_account.sip_accountable.try(:phone_books).all
    if @sip_account.sip_accountable.class == User
      phone_books = phone_books + @sip_account.sip_accountable.try(:current_tenant).try(:phone_books).all
    end

    phone_book_ids = Array.new()
    phone_books.each do |phone_book|
      phone_book_ids << phone_book.id
    end

    PhoneBookEntry.where(:phone_book_id => phone_book_ids).order(:last_name).order(:first_name).limit(MAX_DIRECTORY_ENTRIES).each do |phone_book_entry|
      phone_numbers_count = 0
      phone_book_entry.phone_numbers.each do |phone_number|
        phone_numbers_count += 1
        if phone_numbers_count > 1
          entry_name = ''
        else
          entry_name = phone_book_entry.to_s
        end

        @phone_xml_object[:entries] << { :text => entry_name, :type => phone_number.name, :number => phone_number.number, :url => "tel:#{phone_number.number}" }
      end
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}", :content_type => Mime::HTML
      }
    }

  end


  def idle_screen
    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "idle_screen", :content_type => Mime::HTML
      }
    }
  end
end
