class ConfigGigasetController < ApplicationController

  MAX_SIP_ACCOUNTS = 6
  MAX_HANDSETS = 4

  before_filter {
    @mac_address = params[:mac_address].to_s.upcase.gsub(/[^0-9A-F]/,'')
    @provisioning_key = params[:provisioning_key].to_s
    @build_variant = params[:build_variant].to_i
    @provisioning_id = params[:provisioning_id].to_i
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

    @profile_name = 'GS5'

    config_changed = [@phone.updated_at]
    @phone.phone_sip_accounts.each do |phone_sip_account|
      config_changed << phone_sip_account.updated_at
    end
    #@config_version = Time.now.utc.strftime('%d%m%y%H%M')

    @settings = {
      'BS_IP_Data.ucB_AUTO_UPDATE_PROFILE' => "1",
      'BS_IP_Data3.ucI_ONESHOT_PROVISIONING_MODE_1' => "1",
      'BS_IP_Data1.ucI_DIALING_PLAN_COUNTRY_ID' => "25",
      'BS_IP_Data1.aucS_DATA_SERVER[0]' => "\"#{request.host_with_port}/gigaset\"",
      'BS_IP_Data1.uiI_TIME_COUNTRY' => "25",
      'BS_IP_Data1.uiI_TIME_TIMEZONE' => "27",
      'BS_IP_Data1.ucB_CT_AFTER_ON_HOOK' => "1",
      'BS_CUSTOM_ORG.bit.bEct' => "1",
      'BS_AE_SwConfig.ucCountryCodeTone' => "9",
      'BS_IP_Data1.ucB_ACCEPT_FOREIGN_SUBNET' => "1",
      'BS_IP_Data1.ucB_ACCEPT_FOREIGN_SUBNET..attr' => "1",
      'BS_XML_Netdirs.astNetdirProvider[1].aucServerURL' => '""',
      'BS_XML_Netdirs.astNetdirProvider[1].aucWhitePagesDirName' => '"GS5"',
      'BS_XML_Netdirs.astNetdirProvider[1].aucUsername' => '""',
      'BS_XML_Netdirs.astNetdirProvider[1].aucPassword' => '""',

    }

    for index in 1..MAX_SIP_ACCOUNTS
      @settings["BS_IP_Data1.aucS_SIP_ACCOUNT_NAME_#{index}"] = "\"SIP#{index}\""
      @settings["BS_IP_Data1.ucB_SIP_ACCOUNT_IS_ACTIVE_#{index}"] = "0"
      @settings["BS_IP_Data1.aucS_VOIP_NET_AM_NUMBER_#{index}"] = '"*98#"' 
      @settings["BS_IP_Data1.ucB_VOIP_NET_AM_ENABLED_#{index}"] = "1" 
      @settings["BS_IP_Data1.ucB_SIP_ACCOUNT_IS_ACTIVE_#{index}..attr"] = "UI_LOCK"
      @settings["BS_IP_Data1.ucI_LOUDNESS_#{index}"] = "0" 
      @settings["BS_Accounts.astAccounts[#{index-1}].aucAccountName[0]"] = "\"SIP#{index}\""

      if index == 1
        @settings["BS_IP_Data1.aucS_SIP_DISPLAYNAME"] = '""'
        @settings["BS_IP_Data3.aucS_SIP_LOGIN_ID"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_PASSWORD"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_USER_ID"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_DOMAIN"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_SERVER"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_REGISTRAR"] = '""' 
        @settings["BS_IP_Data1.aucS_STUN_SERVER"] = '""' 
        @settings["BS_IP_Data1.aucS_OUTBOUND_PROXY"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_PROVIDER_NAME"] = '"GS5"' 
        @settings["BS_IP_Data1.uiI_SIP_SERVER_PORT"] = "5060" 
        @settings["BS_IP_Data1.uiI_SIP_REGISTRAR_PORT"] = "5060" 
        @settings["BS_IP_Data1.ucB_SIP_USE_STUN"] = "0" 
        @settings["BS_IP_Data1.uiI_STUN_SERVER_PORT"] = "3478" 
        @settings["BS_IP_Data1.ucI_OUTBOUND_PROXY_MODE"] = "1" 
        @settings["BS_IP_Data1.uiI_OUTBOUND_PROXY_PORT"] = "5060" 
        @settings["BS_IP_Data1.uiI_RE_REGISTRATION_TIMER"] = "60" 
        @settings["BS_IP_Data1.uiI_RE_STUN_TIMER"] = "60" 
        @settings["BS_IP_Data1.ucI_SIP_PREFERRED_VOCODER"] = "0x01,0x00,0x05,0x02,0x03"
        @settings["BS_IP_Data1.ucB_VOIP_CALLFORWARDING_STATUS"] = "0"
      else
        @settings["BS_IP_Data1.aucS_SIP_DISPLAYNAME_#{index}"] = '""'
        @settings["BS_IP_Data3.aucS_SIP_LOGIN_ID_#{index}"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_PASSWORD_#{index}"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_USER_ID_#{index}"] = '""'
        @settings["BS_IP_Data1.aucS_SIP_DOMAIN_#{index}"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_SERVER_#{index}"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_REGISTRAR_#{index}"] = '""' 
        @settings["BS_IP_Data1.aucS_STUN_SERVER_#{index}"] = '""' 
        @settings["BS_IP_Data1.aucS_OUTBOUND_PROXY_#{index}"] = '""' 
        @settings["BS_IP_Data1.aucS_SIP_PROVIDER_NAME_#{index}"] = '"GS5"' 
        @settings["BS_IP_Data1.uiI_SIP_SERVER_PORT_#{index}"] = "5060" 
        @settings["BS_IP_Data1.uiI_SIP_REGISTRAR_PORT_#{index}"] = "5060" 
        @settings["BS_IP_Data1.ucB_SIP_USE_STUN_#{index}"] = "0" 
        @settings["BS_IP_Data1.uiI_STUN_SERVER_PORT_#{index}"] = "3478" 
        @settings["BS_IP_Data1.ucI_OUTBOUND_PROXY_MODE_#{index}"] = "1" 
        @settings["BS_IP_Data1.uiI_OUTBOUND_PROXY_PORT_#{index}"] = "5060" 
        @settings["BS_IP_Data1.uiI_RE_REGISTRATION_TIMER_#{index}"] = "60" 
        @settings["BS_IP_Data1.uiI_RE_STUN_TIMER_#{index}"] = "60" 
        @settings["BS_IP_Data1.ucI_SIP_PREFERRED_VOCODER_#{index}"] = "0x01,0x00,0x05,0x02,0x03"
        @settings["BS_IP_Data1.ucB_VOIP_CALLFORWARDING_STATUS_#{index}"] = "0"
      end
      
      mask = 0
      if index > MAX_HANDSETS
        @settings["BS_Accounts.astAccounts[#{index-1}].ucState"] = 0
      else
        @settings["BS_Accounts.astAccounts[#{index-1}].ucState"] = 1
        mask = 2**(index-1)
      end
      @settings["BS_Accounts.astAccounts[#{index-1}].uiSendMask"] = mask
      @settings["BS_Accounts.astAccounts[#{index-1}].uiReceiveMask"] = mask
    end

    for index in 1..MAX_HANDSETS
      @settings["BS_AE_Subscriber.stMtDat[#{index-1}].aucTlnName"] = "\"HS#{index}\""
    end

    sip_accounts = @phone.sip_accounts.any? ? @phone.sip_accounts : [@phone.fallback_sip_account]

    sip_accounts.each_with_index do |sip_account, index|
      config_changed << sip_account.updated_at
      @settings["BS_IP_Data1.aucS_SIP_ACCOUNT_NAME_#{index+1}"] = "\"#{sip_account.caller_name}\""
      @settings["BS_IP_Data1.ucB_SIP_ACCOUNT_IS_ACTIVE_#{index+1}"] = "1"
      @settings["BS_Accounts.astAccounts[#{index}].aucAccountName[0]"] = "\"ID:#{sip_account.id}\""

      if index == 0
        @settings["BS_IP_Data1.aucS_SIP_DISPLAYNAME"] = "\"#{sip_account.caller_name}\""
        @settings["BS_IP_Data3.aucS_SIP_LOGIN_ID"] = "\"#{sip_account.auth_name}\""
        @settings["BS_IP_Data1.aucS_SIP_PASSWORD"] = "\"#{sip_account.password}\""
        @settings["BS_IP_Data1.aucS_SIP_USER_ID"] = "\"#{sip_account.auth_name}\""
        @settings["BS_IP_Data1.aucS_SIP_DOMAIN"] = "\"#{sip_account.sip_domain}\""
        @settings["BS_IP_Data1.aucS_SIP_SERVER"] = "\"#{sip_account.sip_domain}\""
      else
        @settings["BS_IP_Data1.aucS_SIP_DISPLAYNAME_#{index+1}"] = "\"#{sip_account.caller_name}\""
        @settings["BS_IP_Data3.aucS_SIP_LOGIN_ID_#{index+1}"] = "\"#{sip_account.auth_name}\""
        @settings["BS_IP_Data1.aucS_SIP_PASSWORD_#{index+1}"] = "\"#{sip_account.password}\""
        @settings["BS_IP_Data1.aucS_SIP_USER_ID_#{index+1}"] = "\"#{sip_account.auth_name}\""
        @settings["BS_IP_Data1.aucS_SIP_DOMAIN_#{index+1}"] = "\"#{sip_account.sip_domain}\""
        @settings["BS_IP_Data1.aucS_SIP_SERVER_#{index+1}"] = "\"#{sip_account.sip_domain}\""
      end

      if index <= MAX_HANDSETS-1
        @settings["BS_AE_Subscriber.stMtDat[#{index}].aucTlnName"] = "\"#{sip_account.caller_name}\""
      end
    end

    mask = 0
    for index in 1..MAX_HANDSETS
      if sip_accounts.count <= index
        @settings["BS_AE_Subscriber.stMtDat[#{index-1}].aucTlnName"] = "\"#{index}:#{sip_accounts.last.caller_name}\""
        mask = mask + 2**(index-1)
        @settings["BS_Accounts.astAccounts[#{sip_accounts.count-1}].uiSendMask"] = mask
        @settings["BS_Accounts.astAccounts[#{sip_accounts.count-1}].uiReceiveMask"] = mask
      end
    end

    if sip_accounts.any?
      phone_book_url = "#{request.protocol}#{request.host_with_port}/config_gigaset/#{@phone.id}/#{sip_accounts.first.id}/phone_book.xml"
      @settings['BS_XML_Netdirs.astNetdirProvider[1].aucServerURL'] = "\"#{phone_book_url}\""
    end

    @config_version = config_changed.sort.last.utc.strftime('%d%m%y%H%M')
  end


  def binary
    file_name = params[:file_name].to_s
    block = case file_name
    when /^master/
      block_encode(3, 'sifsroot.bin')
    when /^sifsroot/
      block_encode(4, 'sih.bin')
    when /^sih/
      block_encode(4, 'sit.bin')
    when /^sit/
      block_encode(4, 'siu.bin')
    when /^siu/
      block_encode(0, "#{request.protocol}#{request.host_with_port}/gigaset/%DVID/settings-%MACD.xml")
    end

    send_data block, :type => 'application/octet-stream',:disposition => 'inline'
  end

  def phone_book
    @phone = Phone.where({ :id => params[:phone].to_i }).first
    if ! @phone
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Phone not found -->",
      )
      return false
    end

    if @phone.sip_accounts.any?
      sip_accounts = @phone.sip_accounts
    else
      sip_accounts = [@phone.fallback_sip_account]
    end

    if ! sip_accounts.any?
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SIP account not found -->",
      )
      return false
    end

    base_url = "#{request.protocol}#{request.host_with_port}/config_gigaset/#{@phone.id}/#{sip_accounts.first.id}"
    phone_book_url = "#{base_url}/phone_book.xml"
  end

  private
  def block_encode(block_type, value)
    return [
      block_type,
      value.length+3,
      0x03,
      value.length+1,
      value,
    ].pack("CCCCa#{value.length+1}")

  end
end
