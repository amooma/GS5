require 'nokogiri'
#doc.search('Message/ItemList').each do |a| puts a.children end
class ConfigSiemensController < ApplicationController
#TODO Authentication
	# No access for admins though as this contains personal data.
	
	# We can't use load_and_authorize_resource() here because
	# ConfigSiemensController isn't a resource.
	# We can try client certificates
  MAX_DIRECTORY_ENTRIES = 20

	skip_authorization_check
	
  before_filter { |controller|
    if ! params[:phone].blank?
      @phone = Phone.where({ :id => params[:phone].to_i }).first
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! @sip_account && @phone
      @sip_account = @phone.sip_accounts.where(:sip_accountable_id => @phone.phoneable_id, :sip_accountable_type => @phone.phoneable_type).first
    end
  }


  def index
    os40_keys=6
    os60_keys=8
    os80_keys=9
    doc = Nokogiri::XML(request.body.read)
    #logger.debug("#{params[:WorkpointMessage].to_xml}")
    #logger.debug("#{params[:WorkpointMessage][:Message][:ItemList].to_xml}")
    @phone_items=Hash.new
    contact_reason = params[:WorkpointMessage][:Message][:ReasonForContact]
    fragment = params[:WorkpointMessage][:Message][:fragment]

    reply_status =  doc.search('Message/ReasonForContact').first[:status]
    reply_action =  doc.search('Message/ReasonForContact').first[:action]
    
    doc.search('Message/ItemList/Item').each do |post_item|
      @phone_items[post_item[:name]]=post_item.children.to_s
    end
    if @phone_items['mac-addr']
      mac_address = @phone_items['mac-addr']
    end
    phone_type = @phone_items['device-type']
    if phone_type == "OpenStage 40"
      max_keys = (os40_keys) * 2
    elsif phone_type == "OpenStage 60"
      max_keys = (os60_keys) * 2
    elsif phone_type == "OpenStage 80"
      max_keys = (os80_keys) * 2
    else
      max_keys = 0
    end
    
    blf_keys_max = max_keys / 2
    shift_key_position = blf_keys_max
    
    #logger.debug(request.body.read)
    if mac_address
      @phone = Phone.find_by_mac_address(mac_address.gsub(':','').upcase)

      if ! @phone && GsParameter.get('PROVISIONING_AUTO_ADD_PHONE')
        tenant = Tenant.where(:id => GsParameter.get('PROVISIONING_AUTO_TENANT_ID')).first
        if ! tenant
          render(
            :status => 404,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Tenant not found -->",
          )
          return
        end

        @phone = tenant.phones.build
        @phone.mac_address = mac_address
        @phone.hot_deskable = true
        @phone.phone_model = PhoneModel.where('name LIKE ?', "#{phone_type}").first
        @phone.tenant = tenant
        if ! @phone.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@phone.errors.messages.inspect} -->",
          )
          return
        end

        if ! GsParameter.get('PROVISIONING_AUTO_ADD_SIP_ACCOUNT')
          return
        end

        caller_name_index = 0
        sip_account_last = tenant.sip_accounts.where('caller_name LIKE ?', "#{GsParameter.get('PROVISIONING_AUTO_SIP_ACCOUNT_CALLER_PREFIX')}%").sort { |item1, item2| 
          item1.caller_name.gsub(/[^0-9]/, '').to_i <=> item2.caller_name.gsub(/[^0-9]/, '').to_i
        }.last

        if sip_account_last
          caller_name_index = sip_account_last.caller_name.gsub(/[^0-9]/, '').to_i
        end
        caller_name_index = caller_name_index + 1

        @sip_account = tenant.sip_accounts.build
        @sip_account.caller_name = "#{GsParameter.get('PROVISIONING_AUTO_SIP_ACCOUNT_CALLER_PREFIX')}#{caller_name_index}"
        @sip_account.call_waiting = GsParameter.get('CALL_WAITING')
        @sip_account.clir = GsParameter.get('DEFAULT_CLIR_SETTING')
        @sip_account.clip = GsParameter.get('DEFAULT_CLIP_SETTING')
        @sip_account.voicemail_pin = random_pin
        @sip_account.callforward_rules_act_per_sip_account = GsParameter.get('CALLFORWARD_RULES_ACT_PER_SIP_ACCOUNT_DEFAULT')
        @sip_account.hotdeskable = false
        loop do
          @sip_account.auth_name = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_AUTH_NAME'))
          break unless SipAccount.exists?(:auth_name => @sip_account.auth_name)
        end
        @sip_account.password = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_PASSWORD'))

        if ! @sip_account.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@sip_account.errors.messages.inspect} -->",
          )
          return
        end

        @phone.fallback_sip_account = @sip_account
        if ! @phone.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@phone.errors.messages.inspect} -->",
          )
          return
        end
      end
    end


    country = 'US'
    language = 'en'
    if ! @phone.nil?
      @phone.update_attributes(:ip_address => request.remote_ip)
      @sip_account = @phone.sip_accounts.where(:sip_accountable_type => @phone.phoneable_type,
                                     :sip_accountable_id => @phone.phoneable_id).first

      if !@sip_account
        @sip_account = @phone.fallback_sip_account
      end

      tenant = @phone.tenant

      if @phone.phoneable
        if @phone.phoneable_type == 'Tenant'
          language = tenant.language.code
        elsif @phone.phoneable_type == 'User'
          language = @phone.phoneable.language.code
        end
      end

      if tenant && tenant.country
        country_map = {
          '61' => 'AU', # Australia
          '43' => 'AT', # Austria
          '86' => 'CN', # China
          '45' => 'DK', # Denmark
          '33' => 'FA', # France
          '49' => 'DE', # Germany
          '44' => 'GB', # Great Britain
          '91' => 'IN', # India
          '39' => 'IT', # Italy
          '81' => 'JP', # Japan
          '52' => 'MX', # Mexico
          '31' => 'NL', # Netherlands
          '47' => 'NO', # Norway
          '64' => 'NZ', # New Zealand
          '34' => 'ES', # Spain
          '46' => 'SE', # Sweden
          '41' => 'CH', # Switzerland
        }
        if country_map.include?(tenant.country.country_code)
          country = country_map[tenant.country.country_code]
        end
      end
    end
    
    if ! @phone.nil? && ! @sip_account.blank?
      #logger.debug(@phone_items)
      @my_nonce = params[:WorkpointMessage][:Message][:nonce]
      @new_settings = Array.new
      
      @new_settings << ['dhcp', nil,  'true']
      @new_settings << ['hostname', nil,  mac_address.gsub(':', '') ]
      #@new_settings << ['e164-hostname', nil,  'false']
      @new_settings << ['mobility-enabled', nil,  'false']
      @new_settings << ['mobility-password-on-logoff', nil,  'false']
      @new_settings << ['e164', nil,  @sip_account.auth_name]
      @new_settings << ['sip-user-id', nil,  @sip_account.auth_name]
      #Not supported
      #@new_settings << ['reg-id', nil,  @sip_account.auth_name]
      #@new_settings << ['reg-number', nil,  @sip_account.auth_name]
      #@new_settings << ['fully-qualified-phone-no', nil,  @sip_account.auth_name]
      @new_settings << ['sip-pwd', nil,  @sip_account.password]
      @new_settings << ['sip-name', nil,  @sip_account.caller_name]
      @new_settings << ['register-by-name', nil,  'false']
      @new_settings << ['display-id-unicode', nil,  @sip_account.caller_name]
      @new_settings << ['use-display-id', nil,  'true']
      @new_settings << ['reg-addr', nil,  @sip_account.sip_domain.host]
      @new_settings << ['reg-port', nil,  '5060']
      @new_settings << ['registrar-addr', nil,  @sip_account.sip_domain.host]
      @new_settings << ['registrar-port', nil,  '5060']
      #@new_settings << ['outbound-proxy', nil,  @sip_account.sip_domain.host]
      @new_settings << ['outbound-proxy-user', nil,  @sip_account.auth_name]
      #@new_settings << ['sgnl-gateway-addr', nil,  @sip_account.sip_domain.host]
      #@new_settings << ['sgnl-gateway-port', nil,  '5060' ]
      @new_settings << ['sgnl-gateway-addr-user', nil,  @sip_account.sip_domain.host]
      @new_settings << ['sgnl-gateway-port-user', nil,  '5060'] 
      @new_settings << ['sgnl-route', nil,  '0' ]
      @new_settings << ['mwi-e164', nil,  '' ]
      @new_settings << ['rtp-base-port', nil,  '5004'] 
      @new_settings << ['default-domain', nil,  '' ]
      #@new_settings << ['sip-transport', nil,  '0' ]
      @new_settings << ['sip-transport-user', nil,  '0' ]
      @new_settings << ['server-type', nil,  '0' ]
      @new_settings << ['session-timer', nil,  'false' ]
      @new_settings << ['session-duration', nil,  '3600' ]
      @new_settings << ['reg-ttl', nil,  '3600' ]
      @new_settings << ['realm', nil,   @sip_account.sip_domain.realm]
      @new_settings << ['emergency-e164', nil,  '0110' ]
      @new_settings << ['voice-mail-e164', nil,  'f-vmcheck']
      @new_settings << ['auto-answer', nil,  'false']
      @new_settings << ['beep-on-auto-answer', nil,  'true']
      @new_settings << ['auto-reconnect', nil,  'false' ]
      @new_settings << ['beep-on-auto-reconnect', nil,  'true']
      #@new_settings << ['permit-decline-call', nil,  'true']
      @new_settings << ['transfer-on-ring', nil,  'false' ]
      @new_settings << ['join-allowed-in-conference', nil,  'true']
      @new_settings << ['pickup-group-uri', nil,  "f-ig-#{@sip_account.id}"]
      @new_settings << ['pickup-group-uri', nil,  '' ]
      @new_settings << ['hot-line-warm-line-digits', nil,  '' ]
      @new_settings << ['initial-digit-timer', nil,  '30' ]
      @new_settings << ['conference-factory-uri', nil,  '']
      @new_settings << ['callback-busy-allow', nil,  'false']
      @new_settings << ['callback-busy-code', nil,  '' ]
      @new_settings << ['callback-ring-allow', nil,  'false']
      @new_settings << ['callback-ring-code', nil,  '']
      @new_settings << ['callback-cancel-code', nil,  '']
      @new_settings << ['park-server', nil,  '']
      #OPTIMIZE Callwaiting
      @new_settings << ['call-waiting-enabled', nil,  'true']
      @new_settings << ['qos-layer2', nil,  'true']
      @new_settings << ['l2qos-voice', nil,  '5' ]
      @new_settings << ['l2qos-signalling', nil,  '3' ]
      @new_settings << ['l2qos-default', nil,  '0']
      @new_settings << ['qos-layer3', nil,  'true']
      @new_settings << ['l3qos-voice', nil,  '46']
      @new_settings << ['l3qos-signalling', nil,  '26']
      @new_settings << ['vlan-method', nil,  '1']
      #OPTIMIZE Timezone settings
      @new_settings << ['time', nil, Time.new.localtime.to_i]
      @new_settings << ['sntp-addr', nil,  'NULL']
      @new_settings << ['sntp-tz-offset', nil,  (Time.new.utc_offset/60).to_i]
      @new_settings << ['daylight-save', nil,  'true']
      @new_settings << ['daylight-save-minutes', nil,  '0']
      @new_settings << ['auto-daylight-save', nil,  'true']
      @new_settings << ['daylight-save-zone-id', nil,  '9']
      #OPTIMIZE Use SNMP?
      @new_settings << ['snmp-trap-addr', nil,  'NULL']
      @new_settings << ['snmp-trap-port', nil,  '162']
      @new_settings << ['snmp-trap-pwd', nil,  'snmp' ]
      @new_settings << ['snmp-traps-active', nil,  'false' ]
      @new_settings << ['diagnostic-trap-addr', nil,  'NULL']
      @new_settings << ['diagnostic-trap-port', nil,  '162']
      @new_settings << ['diagnostic-trap-pwd', nil,  'snmp' ]
      @new_settings << ['diagnostic-traps-active', nil,  'false' ]
      @new_settings << ['diagnostic-snmp-active', nil,  'false']
      @new_settings << ['qdc-collection-unit-addr', nil,  'NULL']
      @new_settings << ['qdc-collection-unit-port', nil,  '12010']
      
      @new_settings << ['qdc-trap-pwd', nil,  'QOSDC']
      @new_settings << ['qdc-snmp-active', nil,  'false']
      @new_settings << ['qdc-qcu-active', nil,  'false']
      @new_settings << ['snmp-queries-allowed', nil,  'false']
      #@new_settings << ['snmp-pwd', nil,  '']
      @new_settings << ['disable-microphone', nil,  'false']
      @new_settings << ['loudspeech-enabled', nil,  'true']
      @new_settings << ['audio-silence-suppression', nil,  'false']
      
      @new_settings << ['port1', nil,  '0' ] # 0=Automatic (speed)
      @new_settings << ['port2', nil,  '0'  ]
      @new_settings << ['port2-mode', nil,  '1' ]
      @new_settings << ['port2-auto-mdix-enabled', nil,  'true' ]
      @new_settings << ['originating-line-preference', nil,  '0']
      @new_settings << ['terminating-line-preference', nil,  '0']
      @new_settings << ['line-key-operating-mode', nil,  '0']
      @new_settings << ['line-rollover-type', nil,  '2']
      @new_settings << ['line-rollover-volume', nil,  '5' ]# 1-5
      @new_settings << ['line-registration-leds', nil,  'true']
      @new_settings << ['keyset-use-focus', nil,  'true' ]
      @new_settings << ['keyset-remote-forward-ind', nil,  'true']
      @new_settings << ['keyset-reservation-timer', nil,  '60' ] # 0-300
      @new_settings << ['dial-plan-enabled', nil,  'false' ]
      @new_settings << ['Canonical-dialing-international-prefix', nil,  '']
      @new_settings << ['Canonical-dialing-local-country-code', nil,  '']
      @new_settings << ['Canonical-dialing-national-prefix', nil,  '']
      @new_settings << ['Canonical-dialing-local-area-code', nil,  '']
      @new_settings << ['Canonical-dialing-local-node', nil,  '']
      @new_settings << ['Canonical-dialing-external-access', nil,  '0']
      @new_settings << ['Canonical-dialing-operator-code', nil,  '']
      @new_settings << ['Canonical-dialing-emergency-number', nil,  '']
      @new_settings << ['Canonical-dialing-dial-needs-access-code', nil,  '0']
      @new_settings << ['Canonical-dialing-dial-needs-intGWcode', nil,  '1'] 
      @new_settings << ['Canonical-dialing-min-local-number-length', nil,  '10']
      @new_settings << ['Canonical-dialing-extension-initial-digits', nil,  '']
      @new_settings << ['Canonical-dialing-dial-internal-form', nil,  '0' ]
      @new_settings << ['Canonical-dialing-dial-external-form', nil,  '0' ]
      #@new_settings << ['Canonical-lookup-local-code', nil,  '' ]
      #@new_settings << ['Canonical-lookup-international-code', nil,  '']
      @new_settings << ['hot-keypad-dialing', nil,  'false']
      @new_settings << ['ldap-transport', nil,  '0']
      @new_settings << ['ldap-server-address', nil,  'NULL' ]
      @new_settings << ['ldap-server-port', nil,  '389' ]
      @new_settings << ['ldap-authentication', nil,  '1']
      @new_settings << ['ldap-user', nil,  'NULL' ]
      @new_settings << ['ldap-pwd', nil,  'NULL' ]
      @new_settings << ['ldap-max-responses', nil,  '25'] 
      @new_settings << ['backup-addr', nil,  'NULL']
      @new_settings << ['backup-registration', nil,  'false']
      @new_settings << ['qdc-qcu-active', nil,  'false' ] 
      @new_settings << ['min-admin-passw-length', nil,  '6' ]
      #@new_settings << ['default-locked-config-menus', nil,  'true' ]
      @new_settings << ['locked-config-menus', nil,  'true' ]
      #@new_settings << ['default-locked-local-function-menus', nil,  'true' ]
      @new_settings << ['locked-local-function-menus', nil,  'true' ]
      #@new_settings << ['dls-mode-secure', nil,  '0' ]
      @new_settings << ['dls-chunk-size', nil,  '9492']
      #@new_settings << ['default-passw-policy', nil,  'false']
      @new_settings << ['deflect-destination', nil,  '']
      @new_settings << ['display-skin', nil,  (@phone.phoneable_type == 'User' ? '0' : '1')]
      @new_settings << ['enable-bluetooth-interface', nil,  'true']
      @new_settings << ['usb-access-enabled', nil,  'false' ] 
      @new_settings << ['usb-backup-enabled', nil,  'false' ]
      @new_settings << ['line-button-mode', nil,  '0' ]
      @new_settings << ['lock-forwarding', nil,  '' ]
      @new_settings << ['loudspeaker-function-mode', nil,  '0' ]
      @new_settings << ['max-pin-retries', nil,  '10' ]
      @new_settings << ['screensaver-enabled', nil,  'false' ]
      @new_settings << ['inactivity-timeout', nil,  '60' ]
      @new_settings << ['not-used-timeout', nil,  '5' ]
      @new_settings << ['passw-char-set', nil,  '0' ]
      @new_settings << ['refuse-call', nil,  'true' ]
      @new_settings << ['restart-password', nil,  '124816']
      #OPTIMIZE clock format
      @new_settings << ['time-format', nil,  '0' ]# 1=12 h
      @new_settings << ['uaCSTA-enabled', nil,  'false' ]
      @new_settings << ['enable-test-interface', nil,  'false']
      @new_settings << ['enable-WBM', nil,  'true']
      #@new_settings << ['pixelsaver-timeout', nil,  '2' ]# 2 hours?
      #@new_settings << ['voice-message-dial-tone', nil,  '' ]
      #@new_settings << ['call-pickup-allowed', nil,  'true' ]
      @new_settings << ['group-pickup-tone-allowed', nil,  'true']
      @new_settings << ['group-pickup-as-ringer', nil,  'false']
      @new_settings << ['group-pickup-alert-type', nil,  '0' ]
      #@new_settings << ['default-profile', nil,  '' ]
      @new_settings << ['count-medium-priority', nil,  '5'] 
      @new_settings << ['timer-medium-priority', nil,  '60'] # 1 - 999
      @new_settings << ['timer-high-priority', nil,  '5']  # 0 - 999
      @new_settings << ['dss-sip-detect-timer', nil,  '10'] 
      @new_settings << ['dss-sip-deflect', nil,  'false' ]
      @new_settings << ['dss-sip-refuse', nil,  'false' ]
      @new_settings << ['feature-availability', nil,  'false'] 
      @new_settings << ['feature-availability', nil,  'true' ]
      @new_settings << ['feature-availability', nil,  'true' ]
      @new_settings << ['local-control-feature-availability', nil,  'false' ]
      @new_settings << ['trace-level', nil,  '0' ] # Off
      #@new_settings << ['default-locked-function-keys', nil,  'true' ]# "unknown item"
      @new_settings << ['blf-code', nil,  'f-ia-']   # pickup prefix for softkey function 59 (BLF)
      @new_settings << ['stimulus-feature-code', nil,  true] 
      @new_settings << ['stimulus-led-control-uri', nil,  true] 

      @new_settings << ['min-user-passw-length', nil,  '6' ]# 6 - 24
      #OPTIMIZE language
      @new_settings << ['country-iso', nil,  country ]
      @new_settings << ['language-iso', nil,  language]
      @new_settings << ['date-format', nil,  '0' ] # DD.MM.YYYY
      #OPTIMIZE ringtones
      @new_settings << ['ringer-melody', nil,  '1']
      
      @new_settings << ['ringer-melody', nil,  '2']
      @new_settings << ['ringer-tone-sequence', nil,  '2']

      1.upto(8) do |index|
        @new_settings << ['alert', index,  "Ringer#{index}^#{index}^2^60"]
      end
      @new_settings << ['alert', 9,  "Ringer9^1^1^60"]
      @new_settings << ['alert', 10,  "Ringer10^1^3^60"]
      @new_settings << ['alert', 11,  "Ringer0^0^2^60"]

      #Applications
      @new_settings << ['XML-app-name', 1,  'call_history']
      @new_settings << ['XML-app-control-key', 1,  '3']
      @new_settings << ['XML-app-action', 1, 'update']
      @new_settings << ['XML-app-display-name', 1, 'Call History']
      @new_settings << ['XML-app-program-name', 1, "config_siemens/#{@phone.id}/call_history.xml"]
      @new_settings << ['XML-app-special-instance', 1,  '3']
      @new_settings << ['XML-app-server-addr', 1,  request.host]
      @new_settings << ['XML-app-server-port', 1,  '80']
      @new_settings << ['XML-app-transport', 1,  '0']
      @new_settings << ['XML-app-proxy-enabled', 1,  'false']
      @new_settings << ['XML-app-remote-debug', 1,  'false']
      @new_settings << ['XML-app-debug-prog-name', 1,  '']
      @new_settings << ['XML-app-num-tabs', 1,  '3']
      @new_settings << ['XML-app-restart', 1,  'true']
      @new_settings << ['XML-app-auto-start', 1,  'true']
      @new_settings << ['XML-app-tab1-display-name', 1,  'Missed']
      @new_settings << ['XML-app-tab1-name', 1,  'call_history']
      @new_settings << ['XML-app-tab2-display-name', 1,  'Received']
      @new_settings << ['XML-app-tab2-name', 1,  'call_history_received']
      @new_settings << ['XML-app-tab3-display-name', 1,  'Dialed']
      @new_settings << ['XML-app-tab3-name', 1,  'call_history_dialed']

      @new_settings << ['XML-app-name', 2,  'menu']
      @new_settings << ['XML-app-control-key', 2,  '6']
      @new_settings << ['XML-app-action', 2, 'update']
      @new_settings << ['XML-app-display-name', 2, 'Menu']
      @new_settings << ['XML-app-program-name', 2, "config_siemens/#{@phone.id}/menu.xml"]
      @new_settings << ['XML-app-special-instance', 2,  '0']
      @new_settings << ['XML-app-server-addr', 2,  request.host]
      @new_settings << ['XML-app-server-port', 2,  '80']
      @new_settings << ['XML-app-transport', 2,  '0']
      @new_settings << ['XML-app-proxy-enabled', 2,  'false']
      @new_settings << ['XML-app-remote-debug', 2,  'false']
      @new_settings << ['XML-app-debug-prog-name', 2,  '']
      @new_settings << ['XML-app-num-tabs', 2,  '3']
      @new_settings << ['XML-app-restart', 2,  'true']
      @new_settings << ['XML-app-tab1-display-name', 2,  "Gemeinschaft #{GsParameter.get('GEMEINSCHAFT_VERSION')}"]
      @new_settings << ['XML-app-tab1-name', 2,  'menu']
      @new_settings << ['XML-app-tab2-display-name', 2,  'Status']
      @new_settings << ['XML-app-tab2-name', 2,  'menu_status']
      @new_settings << ['XML-app-tab3-display-name', 2,  'Help']
      @new_settings << ['XML-app-tab3-name', 2,  'menu_help']


      @new_settings << ['clear-calllog', nil, 'true']
      @new_settings << ['server-based-features', nil, 'true']


      if ! @sip_account.call_forwards.blank?
        call_forwarding_object = @sip_account.call_forwards.where(:call_forward_case_id => CallForwardCase.where(:value => 'always').first).first
        if call_forwarding_object
          @new_settings << ['key-functionality', 4002, '1']
          @new_settings << ['function-key-def', 4002, '63']
          @new_settings << ['stimulus-led-control-uri', 4002, "f-cftg-#{call_forwarding_object.id}" ]
          @new_settings << ['send-url-address', 4002, request.host]
          @new_settings << ['send-url-protocol', 4002, 3] # 0=https, 3=http
          @new_settings << ['send-url-port', 4002, '80']
          @new_settings << ['send-url-path', 4002, "/config_siemens/#{@phone.id}/#{@sip_account.id}/call_forwarding.xml"]
          @new_settings << ['send-url-query', 4002, "id=#{call_forwarding_object.id}&function=toggle"]
          @new_settings << ['send-url-method', 4002, '0'] # 0=get, 1=post
        else
          @new_settings << ['key-functionality', 4002, '0']
        end
      else
        @new_settings << ['key-functionality', 4002, '0']
      end

      @new_settings << ['function-key-def', 4003, '10'] # Hold

      @new_settings << ['feature-availability', 2,  'false' ] # call forwarding
      @new_settings << ['feature-availability', 11,  'false' ] # DND
      @new_settings << ['feature-availability', 30,  'false'] # DSS
      @new_settings << ['feature-availability', 31,  'false'] # feature toggle
      @new_settings << ['feature-availability', 33,  'true'] # line overview
      @new_settings << ['feature-availability', 33,  'false'] # phone lock


      @soft_keys = Array.new
      # Fill softkeys with keys dependent on limit of phone      
      @sip_account.softkeys.order(:position).each do |sk|
        @soft_keys << sk
      end
      # Delete unset softkeys
      # OPTIMIZE 40 should be enough for 2 modules, but for some reason array is empty o early
      max_keys = max_keys + 50
      while @soft_keys.length <= max_keys
        @soft_keys << Softkey.new
      end
      
      @key_pos=1
            
      #@soft_keys.each do |sk| 
        
        while @key_pos < shift_key_position
          
          (1..shift_key_position-1).each do |idx|
            first_level_keys(idx)
          end
        end
        if @key_pos == shift_key_position
          @new_settings << ['function-key-def', shift_key_position, '18']
          @new_settings << ['key-label', shift_key_position, 'Shift']
          @new_settings << ['key-label-unicode', shift_key_position, 'Shift']
          @key_pos = @key_pos+1
        end
       
          (1001..1000+shift_key_position-1).each do |idx|
            second_level_keys(idx)
          end
          # First key-module first level 
          (301..311).each do |idx|
            first_level_keys(idx)
          end
          # First key-module shift level
          (1301..1311).each do |idx|
            second_level_keys(idx)
          end
          # Second key-module first level
          (401..411).each do |idx|
            first_level_keys(idx)
          end
          # Second key-module shift level
          (1401..1411).each do |idx|
            second_level_keys(idx)
          end
          [312, 412].each do |idx|
            @new_settings << ['function-key-def', idx, '18']
            @new_settings << ['key-label', idx, 'Shift']
            @new_settings << ['key-label-unicode', idx, 'Shift']
          end
      #end
      logger.debug(@new_settings)
    end
    
    if (@phone.nil? || @sip_account.blank?) && fragment != "final"
      @new_settings = Array.new
      @my_nonce = params[:WorkpointMessage][:Message][:nonce]
      @new_settings << ['e164', nil,  'NULL']
      @new_settings << ['sip-user-id', nil, ""]
      @new_settings << ['sip-pwd', nil, ""]
      @new_settings << ['sip-name', nil, ""]
      @new_settings << ['display-id-unicode', nil, ""]
      @new_settings << ['reg-addr', nil, ""]
      @new_settings << ['registrar-addr', nil, "NULL"]
      @new_settings << ['outbound-proxy-user', nil, ""]
      @new_settings << ['sgnl-gateway-addr-user', nil, ""]
      @new_settings << ['realm', nil, ""]
      @new_settings << ['pickup-group-uri', nil, ""]
      logger.debug(@new_settings)

       respond_to { |format|
        format.xml { render :action => "write" }
      } 
    elsif contact_reason == 'local-changes' 
      respond_to { |format|
        format.xml { render :action => "clean-up" }
      }
    elsif (reply_status == 'accepted' && contact_reason == 'reply-to' && reply_action == 'ReadAllItems')
      respond_to { |format|
        format.xml { render :action => "write" }
      }
      
    elsif ["reply-to"].include? contact_reason 
      respond_to { |format|
        format.xml { render :action => "clean-up" }
      }
      
    else
      respond_to { |format|
        format.xml { render :action => "index" }
      }
    end
    
  end

  def first_level_keys(key_idx)
    sk = @soft_keys.shift
    if sk.softkey_function
      softkey_function = sk.softkey_function.name
    end
    case softkey_function
    when 'blf'
      @new_settings << ['function-key-def', key_idx, '59']
      @new_settings << ['stimulus-led-control-uri', key_idx, sk.number ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, sk.number ]
      @new_settings << ['blf-popup', key_idx, 'true']
    when 'log_out'
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, 'f-lo' ]
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
    when 'log_in'
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, "f-li-#{sk.number}" ]
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
    when 'hold'
      @new_settings << ['function-key-def', key_idx, '10']
      @new_settings << ['select-dial', key_idx, '' ]
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]  
    when 'dtmf'
      @new_settings << ['function-key-def', key_idx, '54']
      @new_settings << ['stimulus-DTMF-sequence', key_idx, sk.number ]
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
    when 'call_forwarding'
      if sk.softkeyable.class == CallForward then
        @new_settings << ['function-key-def', key_idx, '63']
        @new_settings << ['stimulus-led-control-uri', key_idx, "f-cftg-#{sk.softkeyable.id}" ]
        @new_settings << ['send-url-address', key_idx, request.host]
        @new_settings << ['send-url-protocol', key_idx, 3]
        @new_settings << ['send-url-port', key_idx, '80']
        @new_settings << ['send-url-path', key_idx, "/config_siemens/#{@phone.id}/#{@sip_account.id}/call_forwarding.xml"]
        @new_settings << ['send-url-query', key_idx, "id=#{sk.softkeyable.id}&function=toggle"]
        @new_settings << ['send-url-method', key_idx, '0']
        @new_settings << ['blf-popup', key_idx, 'false']
      else
        @new_settings << ['function-key-def', key_idx, '0']
        @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
        @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
      end
    when 'call_forwarding_always'
      phone_number = PhoneNumber.where(:number => sk.number, :phone_numberable_type => 'SipAccount').first
      if phone_number
        account_param = (phone_number.phone_numberable_id != @sip_account.id ? "&account=#{phone_number.phone_numberable_id}" : '')
      else
        phone_number = @sip_account.phone_numbers.first
        account_param = ''
      end
  
      if phone_number
        @new_settings << ['function-key-def', key_idx, '63']
        @new_settings << ['stimulus-led-control-uri', key_idx, "f-cfutg-#{phone_number.id}" ]
        @new_settings << ['send-url-address', key_idx, request.host]
        @new_settings << ['send-url-protocol', key_idx, 3] # 0=https, 3=http
        @new_settings << ['send-url-port', key_idx, '80']
        @new_settings << ['send-url-path', key_idx, "/config_siemens/#{@phone.id}/#{@sip_account.id}/call_forwarding.xml"]
        @new_settings << ['send-url-query', key_idx, "type=always&function=toggle#{account_param}"]
        @new_settings << ['send-url-method', key_idx, '0'] # 0=get, 1=post
      #  @new_settings << ['send-url-user-id', key_idx, 'user']
      #  @new_settings << ['send-url-passwd', key_idx, 'secret']
        @new_settings << ['blf-popup', key_idx, 'false']
      end
    when 'call_forwarding_assistant'
      phone_number = PhoneNumber.where(:number => sk.number, :phone_numberable_type => 'SipAccount').first
      if phone_number
        account_param = (phone_number.phone_numberable_id != @sip_account.id ? "&account=#{phone_number.phone_numberable_id}" : '')
      else
        phone_number = @sip_account.phone_numbers.first
        account_param = ''
      end

      if phone_number
        @new_settings << ['function-key-def', key_idx, '63']
        @new_settings << ['stimulus-led-control-uri', key_idx, "f-cfatg-#{phone_number.id}" ]
        @new_settings << ['send-url-address', key_idx, request.host]
        @new_settings << ['send-url-protocol', key_idx, 3] # 0=https, 3=http
        @new_settings << ['send-url-port', key_idx, '80']
        @new_settings << ['send-url-path', key_idx, "/config_siemens/#{@phone.id}/#{@sip_account.id}/call_forwarding.xml"]
        @new_settings << ['send-url-query', key_idx, "type=assistant&function=toggle#{account_param}"]
        @new_settings << ['send-url-method', key_idx, '0'] # 0=get, 1=post
        @new_settings << ['blf-popup', key_idx, 'false']
      end
    when 'hunt_group_membership'
      phone_number = PhoneNumber.where(:number => sk.number, :phone_numberable_type => 'HuntGroup').first
      if phone_number
        hunt_group = HuntGroup.where(:id => phone_number.phone_numberable_id).first
      end

      sip_account_phone_numbers = Array.new()
      @sip_account.phone_numbers.each do |pn|
        sip_account_phone_numbers.push(pn.number)
      end

      hunt_group_member_numbers = PhoneNumber.where(:number => sip_account_phone_numbers, :phone_numberable_type => 'HuntGroupMember')

      hunt_group_member = nil
      if hunt_group and hunt_group_member_numbers
        hunt_group_member_numbers.each do |hunt_group_member_number|
          hunt_group_member = hunt_group.hunt_group_members.where(:id => hunt_group_member_number.phone_numberable_id).first
          if hunt_group_member
            break
          end
        end
      end

      if hunt_group_member
        @new_settings << ['function-key-def', key_idx, '63']
        @new_settings << ['stimulus-led-control-uri', key_idx, "f-hgmtg-#{hunt_group_member.id}" ]
        @new_settings << ['send-url-address', key_idx, request.host]
        @new_settings << ['send-url-protocol', key_idx, 3] # 0=https, 3=http
        @new_settings << ['send-url-port', key_idx, '80']
        @new_settings << ['send-url-path', key_idx, "/config_siemens/#{@phone.id}/#{@sip_account.id}/hunt_group.xml"]
        @new_settings << ['send-url-query', key_idx, "group=#{hunt_group.id}&account=#{hunt_group_member.id}&function=toggle"]
        @new_settings << ['send-url-method', key_idx, '0'] # 0=get, 1=post
        @new_settings << ['blf-popup', key_idx, 'false']
      end
    when nil
      @new_settings << ['function-key-def', key_idx, '0']
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
    else
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, sk.number ]
      @new_settings << ['stimulus-led-control-uri', key_idx, '' ]
      @new_settings << ['stimulus-DTMF-sequence', key_idx, '' ]
    end
    @new_settings << ['key-label', key_idx, sk.label ]
    @new_settings << ['key-label-unicode', key_idx, sk.label ]
    @key_pos = @key_pos+1 
  end

  def second_level_keys(key_idx)
    sk = @soft_keys.shift
    softkey_function = nil
    if sk.softkey_function
      softkey_function = sk.softkey_function.name
    end
    case softkey_function
    when 'log_out'
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, 'f-lo' ]
    when 'log_in'
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, "f-li-#{sk.number}" ]
    when 'dtmf'
      @new_settings << ['function-key-def', key_idx, '54']
      @new_settings << ['stimulus-DTMF-sequence', key_idx, sk.number ]
    when nil
      @new_settings << ['function-key-def', key_idx, '0']
    else
      @new_settings << ['function-key-def', key_idx, '1']
      @new_settings << ['select-dial', key_idx, sk.number ]
    end
    @new_settings << ['key-label', key_idx, sk.label ]
    @new_settings << ['key-label-unicode', key_idx, sk.label ]
    @key_pos = @key_pos+1
  end

  def call_history
    if ! params[:number].blank?
      number = params[:number]
    end

    if ! params[:function].blank?
      function = params[:function].to_s.downcase
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! @sip_account and ! params[:phonenumber].blank?
      @sip_account = SipAccount.where(:auth_name => params[:phonenumber]).first
    end

    if ! params[:type].blank?
      @type = params[:type]
    elsif ! params[:tab].blank?
      @type = params[:tab].rpartition("_")[2]
    end

    if ! ['dialed', 'missed', 'received'].include? @type
      @type = 'missed'
    end

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"

    @phone_xml_object = { 
      :name => "menu_list",
      :columns => 1,
      :url => base_url,
      :make_call => (function.to_s == 'dial' ? number.to_s : nil),
      :hidden => {:sip_account => @sip_account.id, :type => @type},
      :commands => [{
        :type => 'SELECT',
        :label => 'Dial',
        :display_on => 'LISTITEM',
        :key => 'function',
        :value => 'dial',
      }],
      :entries => [],
    }

    if function.to_s == 'clear_notification'
      @sip_account.call_histories.update_all({:read_flag => true})
    end

    last_missed_call = @sip_account.call_histories.where(:entry_type => 'missed').order('start_stamp DESC').first
    if last_missed_call and !last_missed_call.read_flag
      @phone_xml_object[:led] = true
    else
      @phone_xml_object[:led] = false
    end

    calls = @sip_account.call_histories.where(:entry_type => @type).order('start_stamp DESC').limit(MAX_DIRECTORY_ENTRIES)

    if @type == 'missed' && @phone_xml_object[:led] == true
      @phone_xml_object[:commands].push({
        :type => 'SELECT',
        :label => 'Clear Notification',
        :key => 'function',
        :value => 'clear_notification',
      })
    end

    auto_reload_time = 60

    GsParameter.get('SIEMENS_HISTORY_RELOAD_TIMES').each_pair do |time_range, reload_value|
      if time_range === Time.now.localtime.hour
        auto_reload_time = reload_value
      end
    end

    @phone_xml_object[:commands].push({
      :type => 'UPDATE',
      :auto => auto_reload_time,
      :label => 'Update',
    })

    calls.each do |call|
      display_name = call.display_name
      phone_number = call.display_number
      phone_book_entry = call.phone_book_entry_by_number(phone_number)
      if display_name.blank?
        display_name = phone_book_entry.to_s
      end

      @phone_xml_object[:entries].push({
          :selected => false,
          :key => 'number',
          :value => phone_number,
          :text => "#{call_date_compact(call.start_stamp)}  #{display_name} #{phone_number}",
          })        
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end

  def call_forwarding
    if ! params[:type].blank?
      @type = params[:type]
    end

    if ! params[:function].blank?
      @function = params[:function]
    end

    if ! params[:id].blank?
      @call_forwarding_id = params[:id].to_i
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! params[:account].blank?
      @sip_account = SipAccount.where({ :id => params[:account].to_i }).first
    end

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if @function == 'toggle'
      if @call_forwarding_id 
        call_forwarding = @sip_account.call_forwards.where(:id => @call_forwarding_id).first

        if !call_forwarding and @sip_account.softkeys.where(:softkeyable_id => @call_forwarding_id, :softkeyable_type => 'CallForward').count > 0
          call_forwarding = CallForward.where(:id => @call_forwarding_id).first
        end

        if call_forwarding
          call_forwarding.toggle
        end
      elsif @type
        call_forwarding = @sip_account.call_forwarding_toggle(@type)
      end
      if !call_forwarding
        render(
          :status => 500,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- Call forwarding not set: #{@sip_account.errors.messages.inspect} -->",
        )
        return
      end

      if !call_forwarding.errors.blank?
        error_messages = Array.new()
        call_forwarding.errors.messages.each_pair do |key, message|
          error_messages.push(message.join(';'))
        end
        render(
          :status => 500,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- ERROR #{error_messages.join(',')} #{call_forwarding.to_s}) -->",
        )
      elsif call_forwarding.active
        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- ON #{call_forwarding.to_s} -->",
        )
      else
        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- OFF #{call_forwarding.to_s} -->",
        )
      end
      return
    end

    base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"

    @phone_xml_object = { 
      :name => "number_list",
      :columns => 1,
      :url => base_url,
      :hidden => {:sip_account => @sip_account.id, :type => @type},
      :entries => []
    }

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render
      }
    }
  end


  def hunt_group
    if ! params[:goto].blank?
      redirect_to params[:goto]
      return;
    end

    if ! params[:function].blank?
      @function = params[:function]
    end

    if ! params[:group].blank?
      @hunt_group = HuntGroup.where({ :id => params[:group].to_i }).first
    end

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if ! params[:account].blank?
      hunt_group_member = @hunt_group.hunt_group_members.where({ :id => params[:account].to_i }).first
    end

    base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"

    if @function == 'toggle'
      if ! hunt_group_member
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- HuntGroupMember not found -->",
        )
        return
      end

      if hunt_group_member.can_switch_status_itself == true
        if hunt_group_member.active
          hunt_group_member.active = false
        else
          hunt_group_member.active = true
        end

        if ! hunt_group_member.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{hunt_group_member.errors.inspect} -->",
          )
        else
          render(
            :status => 200,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Member #{hunt_group_member.id} toggled -->",
          )
        end
        return
      end
    elsif @function == 'members'
      commands = [{
        :type => 'UPDATE',
        :auto => 20,
        :label => 'Update',
      },{
        :type => 'BACK',
        :label => 'Back',
        :display_on => 'OPTIONS',
      },{
        :type => 'EXIT',
        :label => 'Exit',
        :display_on => 'OPTIONS',
      },{
        :type => 'SELECT',
        :label => 'Show',
        :display_on => 'LISTITEM',
      }]

      @phone_xml_object = { 
        :name => "menu_list",
        :columns => 1,
        :url => base_url,
        :hidden => {:function => @function, :group => @hunt_group.id},
        :entries => [],
        :commands => commands,
      }

      @hunt_group.hunt_group_members.where(:active => true).each do |member|
        @phone_xml_object[:entries].push({
          :selected => false,
          :value => member.id,
          :text => member.name,
        })
      end
    else
      hunt_groups = Array.new()
      phone_numbers = Array.new()
      @sip_account.phone_numbers.each do |phone_number|
        phone_numbers.push(phone_number.number)
        assistant_call_forwardings = phone_number.call_forwards.where(:call_forward_case_id => CallForwardCase.where(:value => 'assistant').first.id)
        assistant_call_forwardings.each do |assistant_call_forwarding|
          if assistant_call_forwarding.destinationable_type == 'HuntGroup' && assistant_call_forwarding.destinationable_id.to_i > 0
            hunt_groups.push(assistant_call_forwarding.destinationable_id.to_i)
          end
        end
      end

      hunt_group_members = Array.new()
      if phone_numbers.length > 0
        hunt_group_members = PhoneNumber.where(:phone_numberable_type => 'HuntGroupMember', :number => phone_numbers)
      end

      hunt_group_members.each do |hunt_group|
        hunt_groups.push(hunt_group.phone_numberable.hunt_group_id)
      end

      hunt_groups = HuntGroup.where(:id => hunt_groups)

      @phone_xml_object = { 
        :name => "menu_list",
        :columns => 1,
        :url => base_url,
        :hidden => {:function => 'members'},
        :entries => [],
        :commands => [{
          :type => 'EXIT',
          :label => 'Exit',
          :display_on => 'OPTIONS',
        },{
          :type => 'BACK',
          :label => 'Back',
          :display_on => 'OPTIONS',
        },{
          :type => 'SELECT',
          :label => 'Select',
          :display_on => 'LISTITEM',
        }],
      }

      hunt_groups.each do |hunt_group|
        @phone_xml_object[:entries].push({
          :selected => false,
          :key => 'group',
          :value => hunt_group.id,
          :text => hunt_group.name,
        })
      end

    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end


  def menu
    if ! @phone or ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Phone or SipAccount not found -->",
      )
      return
    end

    type = 'menu'
    if ! params[:type].blank?
      type = params[:type]
    elsif ! params[:tab].blank?
      tab = params[:tab].rpartition("_")
      if tab[1] != '' 
        type = tab[2]
      end
    end

    if ! params[:item].blank?
      item = params[:item]
    end

    menu_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"
    base_url = "#{request.protocol}#{request.host_with_port}/config_siemens/#{@phone.id}"

    @phone_xml_object = { 
      :name => "menu_list",
      :columns => 1,
      :url => menu_url,
      :hidden => {:type => type},
      :entries => []
    }

    case type
    when 'menu'
      items = [
        {
        :value => 'phone_directory',
        :text => "Directory",
        :url => "#{menu_url}?type=#{type}",
        },{
        :value => 'call_history',
        :text => "Call History",
        :url => "#{menu_url}?type=call_history",
        },
      ]
    when 'status'
      items = [
        {
        :value => 'hunt_group',
        :text => "Hunt Group",
        :url => "#{base_url}/hunt_group.xml"
        },
      ]

      commands = [
        {
          :type => 'UPDATE',
          :auto => 10,
          :label => 'Update',
        }
      ]
    when 'help'
      items = [
        {
        :key => 'item',
        :value => 'help',
        :text => "Help",
        :url => "#{menu_url}?type=#{type}",
        },
      ]
    when 'call_history'
      items = [
        {
        :value => 'missed',
        :text => "Missed",
        :url => "#{base_url}/call_history.xml?type=missed",
        },{
        :value => 'dialed',
        :text => "Dialed",
        :url => "#{base_url}/call_history.xml?type=dialed",
        },{
        :value => 'received',
        :text => "Received",
        :url => "#{base_url}/call_history.xml?type=received",
        },
      ]
    end

    if item 
      items.each do |entry|
        if entry[:value] == item
          redirect_to entry[:url]
          return;
        end
      end
    end

    @phone_xml_object[:entries] = items
    @phone_xml_object[:commands] = commands    

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end

  def call_date_compact(date)
    if date.strftime('%Y%m%d') == DateTime::now.strftime('%Y%m%d')
      return date.strftime('%H:%M')
    end
    return date.strftime('%d.%m %H:%M')
  end
end
