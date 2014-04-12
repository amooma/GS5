class ConfigPingtelController < ApplicationController

  before_filter {
    @mac_address = params[:PHYSICAL_ID].to_s.upcase.gsub(/[^0-9A-F]/,'')
  }

  def show
    if @mac_address
      @phone = Phone.where(:mac_address => @mac_address).first
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

    @settings = {
      'PHONESET_DEPLOYMENT_SERVER' => "#{request.host_with_port}",
      'PHONESET_ADMIN_DOMAIN' => 'gemeinschaft',
      'PHONESET_LOGICAL_ID' => '1',
      'PHONESET_EXTERNAL_IP_ADDRESS' => '',  
      'PHONESET_DIALPLAN_LENGTH' => '4',
      'PHONESET_LINE.ALLOW_FORWARDING' => 'ENABLE',
      'PHONESET_LINE.REGISTRATION' => 'REGISTER',
      'PHONESET_LINE.URL' => '',
      'PHONESET_AVAILABLE_BEHAVIOR' => 'RING',
      'PHONESET_BUSY_BEHAVIOR' => 'BUSY',
      'PHONESET_CALL_WAITING_BEHAVIOR' => 'ALERT',
      'PHONESET_DND_METHOD' => 'FORWARD_ON_BUSY',
      'PHONESET_HTTP_PORT' => '80',
      'PHONESET_HTTP_PROXY_HOST' => '',
      'PHONESET_HTTP_PROXY_PORT' => '',
      'PHONESET_LOGO_URL' => '',
      'PHONESET_MSG_WAITING_SUBSCRIBE' => '',
      'PHONESET_RINGER' => 'BOTH',
      'PHONESET_SNMP_TRAP_DESTS' => '',
      'PHONESET_TELNET_ACCESS' => 'DISABLE',
      'PHONESET_TIME_DST_RULE' => 'WESTERN_EUROPE',
      'PHONESET_TIME_OFFSET' => '+60',
      'PHONESET_TIME_SERVER' => '130.149.17.21',
      'PHONESET_VOICEMAIL_RETRIEVE' => '',
      'SIP_DIRECTORY_SERVERS' => '',
      'SIP_PROXY_SERVERS' => '',
      'SIP_AUTHENTICATE_SCHEME' => 'NONE',
      'SIP_FORWARD_ON_BUSY' => '',
      'SIP_FORWARD_ON_NO_ANSWER' => '',
      'SIP_FORWARD_UNCONDITIONAL' => '',
      'SIP_REGISTER_PERIOD' => '3600',
      'SIP_SESSION_REINVITE_TIMER' => '',
      'SIP_TCP_PORT' => '', 
      'SIP_UDP_PORT' => '1032',
      'USER_DEFAULT_OUTBOUND_LINE' => 'PHONESET_LINE',
    }

    sip_accounts = Array.new

    if @phone.sip_accounts.any?
      sip_accounts = @phone.sip_accounts
    elsif @phone.fallback_sip_account
      sip_accounts << @phone.fallback_sip_account
    end

    if sip_accounts.any?
      sip_account = sip_accounts.first
      @settings['PHONESET_DEPLOYMENT_SERVER'] = sip_account.sip_domain
      @settings['PHONESET_LINE.URL'] = "\"#{sip_account.caller_name}\" <sip:#{sip_account.auth_name}@#{sip_account.sip_domain}>"
      @settings['SIP_DIRECTORY_SERVERS'] = "sip:#{sip_account.sip_domain}"
      @settings['SIP_PROXY_SERVERS'] = "sip:#{sip_account.sip_domain}"
      #@settings['PHONESET_DIGITMAP.(xxxx|xxxxxxxxxx|1xxxxxxxxxx|91xxxxxxxxxx|9xxxxxxxxxx)'] = "\"{digits}\" <sip:{digits}@#{sip_account.sip_domain}>"
      @settings['PHONESET_VOICEMAIL_RETRIEVE'] = "sip:f-vmcheck@#{sip_account.sip_domain}"
      if sip_account.voicemail_account
        @settings['PHONESET_MSG_WAITING_SUBSCRIBE'] = "sip:#{sip_account.voicemail_account.name}@#{sip_account.sip_domain}"
      end
    end

    sip_accounts.each_with_index do |sip_account, index|
      @settings["PHONESET_LINE.CREDENTIAL.#{index+1}.PASSTOKEN"] = Digest::MD5.hexdigest("#{sip_account.auth_name}:#{sip_account.sip_domain}:#{sip_account.password}")
      @settings["PHONESET_LINE.CREDENTIAL.#{index+1}.REALM"] = sip_account.sip_domain
      @settings["PHONESET_LINE.CREDENTIAL.#{index+1}.USERID"] = sip_account.auth_name
    end
  end
end
