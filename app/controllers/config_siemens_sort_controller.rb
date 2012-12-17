require 'nokogiri'
#doc.search('Message/ItemList').each do |a| puts a.children end
class ConfigSiemensController < ApplicationController
#TODO Authentication
	# No access for admins though as this contains personal data.
	
	# We can't use load_and_authorize_resource() here because
	# ConfigSiemensController isn't a resource.
	# We can try client certificates

	skip_authorization_check
	
	
  def index
    os40_keys=7
    os60_keys=8
    os80_keys=9
    doc = Nokogiri::XML(request.body.read)
    #logger.debug("#{params[:WorkpointMessage].to_xml}")
    #logger.debug("#{params[:WorkpointMessage][:Message][:ItemList].to_xml}")
    @phone_items=Hash.new
    contact_reason = params[:WorkpointMessage][:Message][:ReasonForContact]
    reply_status =  doc.search('Message/ReasonForContact').first[:status]
    reply_action =  doc.search('Message/ReasonForContact').first[:action]
    
    doc.search('Message/ItemList/Item').each do |post_item|
      @phone_items[post_item[:name]]=post_item.children.to_s
    end
    
    mac_address = @phone_items['mac-addr']
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
    shift_key_position = blf_keys_max - 1
    
    #logger.debug(request.body.read)
    @phone = Phone.find_by_mac_address(mac_address.gsub(':','').upcase)
    if ! @phone.nil?
      @phone.update_attributes(:ip_address => request.remote_ip)
      sip_account = SipAccount.where(:sip_accountable_type == @phone.phoneable_type,
                                     :sip_accountable_id == @phone.phoneable_id).first
    end
    
    if ! @phone.nil? && ! sip_account.nil?
      #logger.debug(@phone_items)
      @my_nonce = params[:WorkpointMessage][:Message][:nonce]
      @new_settings = Array.new
      
      @new_settings << ['dhcp', nil,  'true']
      @new_settings << ['hostname', nil,  mac_address.gsub(':', '') ]
      @new_settings << ['e164-hostname', nil,  'false']
      @new_settings << ['mobility-enabled', nil,  'false']
      @new_settings << ['mobility-password-on-logoff', nil,  'false']
      @new_settings << ['e164', nil,  sip_account.try(:phone_numbers).first.number]
      @new_settings << ['sip-user-id', nil,  sip_account.auth_name]
      @new_settings << ['reg-id', nil,  sip_account.auth_name]
      @new_settings << ['reg-number', nil,  sip_account.auth_name]
      @new_settings << ['fully-qualified-phone-no', nil,  sip_account.auth_name]
      @new_settings << ['sip-pwd', nil,  sip_account.password]
      @new_settings << ['sip-name', nil,  sip_account.caller_name]
      @new_settings << ['register-by-name', nil,  'false']
      #OPTIMIZE Display ID ?
      @new_settings << ['display-id', nil,  sip_account.try(:phone_numbers).first.number]
      @new_settings << ['display-id-unicode', nil,  sip_account.caller_name]
      @new_settings << ['use-display-id', nil,  'true']
      @new_settings << ['reg-addr', nil,  sip_account.sip_domain.host]
      @new_settings << ['reg-port', nil,  '5060']
      @new_settings << ['registrar-addr', nil,  sip_account.sip_domain.host]
      @new_settings << ['registrar-port', nil,  '5060']
      @new_settings << ['outbound-proxy', nil,  sip_account.sip_domain.host]
      @new_settings << ['outbound-proxy-user', nil,  sip_account.sip_domain.host]
      @new_settings << ['sgnl-gateway-addr', nil,  sip_account.sip_domain.host]
      @new_settings << ['sgnl-gateway-addr-user', nil,  sip_account.sip_domain.host]
      @new_settings << ['sgnl-gateway-port', nil,  '5060' ]
      @new_settings << ['sgnl-gateway-port-user', nil,  '5060'] 
      @new_settings << ['sgnl-route', nil,  '0' ]
      @new_settings << ['mwi-e164', nil,  '' ]
      @new_settings << ['rtp-base-port', nil,  '5004'] 
      @new_settings << ['default-domain', nil,  '' ]
      @new_settings << ['sip-transport', nil,  '0' ]
      @new_settings << ['sip-transport-user', nil,  '0' ]
      @new_settings << ['server-type', nil,  '0' ]
      @new_settings << ['session-timer', nil,  'true'] 
      @new_settings << ['session-duration', nil,  '3600' ]
      @new_settings << ['reg-ttl', nil,  '3600' ]
      @new_settings << ['realm', nil,   sip_account.sip_domain.realm]
      @new_settings << ['emergency-e164', nil,  '0110' ]
      @new_settings << ['voice-mail-e164', nil,  'voicemail']
      @new_settings << ['auto-answer', nil,  'false']
      @new_settings << ['beep-on-auto-answer', nil,  'true']
      @new_settings << ['auto-reconnect', nil,  'false' ]
      @new_settings << ['beep-on-auto-reconnect', nil,  'true']
      @new_settings << ['permit-decline-call', nil,  'true']
      @new_settings << ['transfer-on-ring', nil,  'false' ]
      @new_settings << ['join-allowed-in-conference', nil,  'true']
      @new_settings << ['pickup-group-uri', nil,  '*8*']
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
      #OPTIMIZE Timezone
      @new_settings << ['sntp-tz-offset', nil,  '']
      @new_settings << ['daylight-save', nil,  '']
      @new_settings << ['daylight-save-minutes', nil,  '']
      #OPTIMIZE Use SNMP?
      @new_settings << ['snmp-trap-addr', nil,  '']
      @new_settings << ['snmp-trap-port', nil,  '']
      @new_settings << ['snmp-trap-pwd', nil,  'snmp' ]
      @new_settings << ['snmp-traps-active', nil,  'false' ]
      @new_settings << ['diagnostic-trap-addr', nil,  '']
      @new_settings << ['diagnostic-trap-port', nil,  '']
      @new_settings << ['diagnostic-trap-pwd', nil,  'snmp' ]
      @new_settings << ['diagnostic-traps-active', nil,  'false' ]
      @new_settings << ['diagnostic-snmp-active', nil,  'false']
      @new_settings << ['qdc-collection-unit-addr', nil,  '']
      @new_settings << ['qdc-collection-unit-port', nil,  '12010']
      
      @new_settings << ['qdc-trap-pwd', nil,  'QOSDC']
      @new_settings << ['qdc-snmp-active', nil,  'false']
      @new_settings << ['qdc-qcu-active', nil,  'false']
      @new_settings << ['snmp-queries-allowed', nil,  'false']
      @new_settings << ['snmp-pwd', nil,  '']
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
      @new_settings << ['dial-plan-enabled', nil,  '' ]
      @new_settings << ['Canonical-dialing-international-prefix', nil,  '']
      @new_settings << ['Canonical-dialing-local-country-code', nil,  '']
      @new_settings << ['Canonical-dialing-national-prefix', nil,  '']
      @new_settings << ['Canonical-dialing-local-area-code', nil,  '']
      @new_settings << ['Canonical-dialing-local-node', nil,  '']
      @new_settings << ['Canonical-dialing-external-access', nil,  '0']
      @new_settings << ['Canonical-dialing-operator-code', nil,  '']
      @new_settings << ['Canonical-dialing-emergency-number', nil,  '']
      @new_settings << ['Canonical-dialing-dial-needs-access-code', nil,  '0']
      @new_settings << ['Canonical-dialing-dial-needs-intGWcode', nil,  '0'] 
      @new_settings << ['Canonical-dialing-min-local-number-length', nil,  '10']
      @new_settings << ['Canonical-dialing-extension-initial-digits', nil,  '']
      @new_settings << ['Canonical-dialing-dial-internal-form', nil,  '0' ]
      @new_settings << ['Canonical-dialing-dial-external-form', nil,  '0' ]
      @new_settings << ['Canonical-lookup-local-code', nil,  '' ]
      @new_settings << ['Canonical-lookup-international-code', nil,  '']
      @new_settings << ['hot-keypad-dialing', nil,  '']
      @new_settings << ['ldap-transport', nil,  '0']
      @new_settings << ['ldap-server-address', nil,  '' ]
      @new_settings << ['ldap-server-port', nil,  '389' ]
      @new_settings << ['ldap-authentication', nil,  '1']
      @new_settings << ['ldap-user', nil,  '' ]
      @new_settings << ['ldap-pwd', nil,  '' ]
      @new_settings << ['ldap-max-responses', nil,  '25'] 
      @new_settings << ['backup-addr', nil,  ''] 
      @new_settings << ['backup-registration', nil,  'false']
      @new_settings << ['qdc-qcu-active', nil,  'false' ] 
      @new_settings << ['min-admin-passw-length', nil,  '6' ]
      @new_settings << ['default-locked-config-menus', nil,  'true' ]
      @new_settings << ['locked-config-menus', nil,  'true' ]
      @new_settings << ['default-locked-local-function-menus', nil,  'true' ]
      @new_settings << ['locked-local-function-menus', nil,  'true' ]
      @new_settings << ['dls-mode-secure', nil,  '0' ]
      @new_settings << ['dls-chunk-size', nil,  '9492']
      @new_settings << ['default-passw-policy', nil,  'false']
      @new_settings << ['deflect-destination', nil,  '']
      @new_settings << ['display-skin', nil,  '']
      @new_settings << ['enable-bluetooth-interface', nil,  'true']
      @new_settings << ['usb-access-enabled', nil,  'false' ] 
      @new_settings << ['usb-backup-enabled', nil,  'false' ]
      @new_settings << ['line-button-mode', nil,  '0' ]
      @new_settings << ['lock-forwarding', nil,  '' ]
      @new_settings << ['loudspeaker-function-mode', nil,  '0' ]
      @new_settings << ['max-pin-retries', nil,  '' ]
      @new_settings << ['inactivity-timeout', nil,  '30' ] 
      @new_settings << ['not-used-timeout', nil,  '2' ]
      @new_settings << ['passw-char-set', nil,  '0' ]
      @new_settings << ['refuse-call', nil,  'true' ]
      @new_settings << ['restart-password', nil,  '']
      #OPTIMIZE clock format
      @new_settings << ['time-format', nil,  '0' ]# 1=12 h
      @new_settings << ['uaCSTA-enabled', nil,  'false' ]
      @new_settings << ['enable-test-interface', nil,  'false']
      @new_settings << ['enable-WBM', nil,  'true']
      @new_settings << ['pixelsaver-timeout', nil,  '2' ]# 2 hours?
      @new_settings << ['voice-message-dial-tone', nil,  '' ]
      @new_settings << ['call-pickup-allowed', nil,  'true' ]
      @new_settings << ['group-pickup-tone-allowed', nil,  'true']
      @new_settings << ['group-pickup-as-ringer', nil,  'false']
      @new_settings << ['group-pickup-alert-type', nil,  '0' ]
      @new_settings << ['default-profile', nil,  '' ]
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
      @new_settings << ['default-locked-function-keys', nil,  'true' ]# "unknown item"
      #OPTIMIZE Put pickup prefix into database/global constant?
      @new_settings << ['blf-code', nil,  'f_ia_']   # pickup prefix for softkey function 59 (BLF)
      @new_settings << ['stimulus-feature-code', nil,  true] 
      @new_settings << ['stimulus-led-control-uri', nil,  true] 
      
      
      @new_settings << ['min-user-passw-length', nil,  '6' ]# 6 - 24
      #OPTIMIZE language
      @new_settings << ['country-iso', nil,  'DE' ]
      @new_settings << ['language-iso', nil,  'de']
      @new_settings << ['date-format', nil,  '0' ] # DD.MM.YYYY
      #OPTIMIZE ringtones
      @new_settings << ['ringer-melody', nil,  '1']
      
      @new_settings << ['ringer-melody', nil,  '2']
      @new_settings << ['ringer-tone-sequence', nil,  '2']
      
      soft_keys = Array.new
           # Getting BLF keys only for the first level 
      blf_keys = sip_account.softkeys.find(
                      :all,
                      :conditions => {:function => ['blf', 'conference']},
                      :limit => blf_keys_max)
      #Getting other keys
      non_blf_keys = sip_account.softkeys.find(
                      :all,
                      :conditions => {:function => ['speed_dial']})
 
      # Fill softkey array with BLF keys up to shift key
      blf_keys.each do |k|    
        soft_keys << k
      end
      # Fill sofkey with other keys up to end
      non_blf_keys.each do |k| 
        if soft_keys.length < max_keys      
          soft_keys << k
        end
      end
      # Delete unset softkeys
      while soft_keys.length < max_keys
        soft_keys << Softkey.new
      end
      
      key_pos=1
            
      #soft_keys.each do |sk| 
        
        while key_pos < shift_key_position
          
          (1..shift_key_position-1).each do |key_idx|
            sk = soft_keys.shift          
            logger.debug(sk.function, key_idx)
            if sk.function == "blf"
              @new_settings << ['function-key-def', key_idx, '59']
              @new_settings << ['select-dial', key_idx, sk.number ]
            elsif sk.function == "log_out"
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, 'f_lo' ]
            elsif sk.function == "log_in"
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, "f_li_#{sk.number}" ]
            elsif sk.function == "dtmf"
              @new_settings << ['function-key-def', key_idx, '54']
              @new_settings << ['stimulus-DTMF-sequence', key_idx, sk.number ]
            elsif sk.function.nil?
              @new_settings << ['function-key-def', key_idx, '0']
            else
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, sk.number ]
            end
            @new_settings << ['key-label', key_idx, sk.label ]
            @new_settings << ['key-label-unicode', key_idx, sk.label ]
            key_pos = key_pos+1
            
          end
        end
        if key_pos == shift_key_position
          @new_settings << ['function-key-def', shift_key_position, '18']
          @new_settings << ['key-label', shift_key_position, 'Shift']
          @new_settings << ['key-label-unicode', shift_key_position, 'Shift']
          key_pos = key_pos+1
        end
       
          (1001..1000+shift_key_position-1).each do |key_idx|
            sk = soft_keys.shift
            if sk.function == "log_out"
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, 'f_lo' ]
            elsif sk.function == "log_in"
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, "f_li_#{sk.number}" ]
            elsif sk.function == "dtmf"
              @new_settings << ['function-key-def', key_idx, '54']
              @new_settings << ['stimulus-DTMF-sequence', key_idx, sk.number ]
            elsif sk.function.nil?
              @new_settings << ['function-key-def', key_idx, '0']
            else
              @new_settings << ['function-key-def', key_idx, '1']
              @new_settings << ['select-dial', key_idx, sk.number ]
            end
            @new_settings << ['key-label', key_idx, sk.label ]
            @new_settings << ['key-label-unicode', key_idx, sk.label ]
            key_pos = key_pos+1
 
          end
        
      #end
      logger.debug(@new_settings)
    end
    
    if @phone.nil? || sip_account.nil?
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
end
