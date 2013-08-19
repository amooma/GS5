class ConfigYealinkController < ApplicationController

  MAX_SIP_ACCOUNTS = 5
  MAX_HANDSETS = 5
  MAX_PHONEBOOK_ENTRIES = 1000
  IGNORE_PHONEBOOK_EXCEEDING = 500
  SIP_DEFAULT_PORT = 5060

  before_filter {
    @mac_address = params[:mac_address].to_s.upcase.gsub(/[^0-9A-F]/,'')
  }

  def show
    if @mac_address
      @phone = Phone.where(:mac_address => @mac_address).first
    end

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
      @phone.mac_address = @mac_address
      @phone.hot_deskable = true
      @phone.tenant = tenant
      @phone.http_user = 'admin'

      if !GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').nil? && @phone.http_password.blank?
        if GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').class == Fixnum
          @phone.update_attributes({ :http_password => SecureRandom.hex(GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD')) })
        elsif GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').class == String
          @phone.update_attributes({ :http_password => GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD') })
        end
      end

      phone_model = nil
      if request.env['HTTP_USER_AGENT'].index('W52P')
        phone_model = PhoneModel.where(:name => 'Yealink W52P').first 
      end

      if ! phone_model
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- Phone Model not found in: \"#{request.env['HTTP_USER_AGENT']}\" -->",
        )
        return
      end

      @phone.phone_model = phone_model
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

    base_url = "#{request.protocol}#{request.host_with_port}/config_yealink/#{@phone.id}/#{sip_accounts.first.id}/"
    @phonebook_url = base_url + 'phone_book.xml'

    @sip_accounts = Array.new(MAX_SIP_ACCOUNTS) {|index|
      sip_account = sip_accounts[index]
      sip_account_entry = sip_account_defaults

      if sip_account
        sip_account_entry['enable'] = '1'
        sip_account_entry['label']  = sip_account.caller_name
         sip_account_entry['auth_name']  = sip_account.auth_name
         sip_account_entry['password']  = sip_account.password
         sip_account_entry['user_name']  = sip_account.auth_name
         sip_account_entry['sip_server_host']  = sip_account.sip_domain
         sip_account_entry['outbound_host'] = sip_account.sip_domain
         sip_account_entry['sip_listen_port'] = 5060 + (index*2)
      end

      sip_account_entry
    }

    @handsets = Array.new(MAX_HANDSETS) {|index|
      handset = {}
      sip_account = sip_accounts[index]
      if sip_account
        handset['name'] = sip_account.caller_name
      else
        handset['name'] = "Handset #{index+1}"
      end

      handset
    }

    @provisioning_url = "#{request.protocol}#{request.host_with_port}"

    if ! request.env['HTTP_USER_AGENT'].index('Yealink')
      Rails.logger.info "---> User-Agent indicates not a Yealink phone (#{request.env['HTTP_USER_AGENT'].inspect})"
    else
      Rails.logger.info "---> Phone #{@mac_address.inspect}, IP address #{request_remote_ip.inspect}"
      @phone.update_attributes({ :ip_address => request_remote_ip })
    end
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

    base_url = "#{request.protocol}#{request.host_with_port}/config_yealink/#{@phone.id}/#{sip_accounts.first.id}"
    @phonebook_url = "#{base_url}/phone_book.xml"

    @phone_books = Array.new()
    tenant = nil
    phone_book_ids = {}
    if @phone.phoneable.class == User
      @phone.phoneable.phone_books.each do |phone_book|
        if @phone_books.count >= MAX_PHONEBOOK_ENTRIES
          break
        end
        if phone_book.phone_book_entries.count > IGNORE_PHONEBOOK_EXCEEDING
          next
        end

        @phone_books << {:name => phone_book.name, :url => "#{base_url}/#{phone_book.id}/phone_book.xml"}
        phone_book_ids[phone_book.id]
      end
      tenant = @phone.phoneable.current_tenant
    elsif @phone.phoneable.class == Tenant
      tenant = @phone.phoneable
    end

    if tenant
      tenant.phone_books.each do |phone_book|
        if @phone_books.count >= MAX_PHONEBOOK_ENTRIES
          break
        end
        if phone_book.phone_book_entries.count > IGNORE_PHONEBOOK_EXCEEDING
          next
        end

        @phone_books << {:name => phone_book.name, :url => "#{base_url}/#{phone_book.id}/phone_book.xml"}
        phone_book_ids[phone_book.id]
      end
    end

    phone_book_id = params[:phone_book].to_i
    if @phone_books.any? && phone_book_ids[phone_book_id]
      @phone_book = PhoneBook.where(:id => phone_book_id).first
    end

    @phone_book = PhoneBook.where(:id => phone_book_id).first

    if @phone_book
      respond_to { |format|
        format.any {
          self.formats = [ :xml ]
          render :action => '_phone_directory'
        }
      }
    else
      respond_to { |format|
        format.any {
          self.formats = [ :xml ]
          render :action => '_phone_menu'
        }
      }
    end

  end

  private 
  def sip_account_defaults
    sip_account_entry = {
      'enable' => '0',
      'label' => '',
      'display_name' => 'Call',
      'auth_name' => '',
      'password' => '',
      'user_name' => '',
      'sip_server_host' => '',
      'sip_server_port' => SIP_DEFAULT_PORT,
      'outbound_proxy_enable' => '1',
      'outbound_host' => '',
      'outbound_port' => SIP_DEFAULT_PORT,
      'transport' => '0',
      'backup_outbound_host' => '',
      'backup_outbound_port' => '',
      'anonymous_call' => '0',
      'anonymous_call_oncode' => '',
      'anonymous_call_offcode' => '',
      'reject_anonymous_call' => '0',
      'anonymous_reject_oncode' => '',
      'anonymous_reject_offcode' => '',
      'sip_listen_port' => '',
      'expires' => '',
      '100rel_enable' => '',
      'precondition' => '',
      'subscribe_register' => '',
      'subscribe_mwi' => '1',
      'subscribe_mwi_expires' => '',
      'cid_source' => '',
      'session_timer.enable' => '',
      'session_timer.expires' => '',
      'session_timer.refresher' => '',
      'enable_user_equal_phone' => '',
      'srtp_encryption' => '',
      'ptime' => '',
      'subscribe_mwi_to_vm' => '1',
      'register_mac' => '',
      'register_line' => '',
      'reg_fail_retry_interval' => '',
      'enable_signal_encode' => '',
      'signal_encode_key' => '',
      'dtmf.type' => '1',
      'dtmf.dtmf_payload' => '',
      'dtmf.info_type' => '',
      'dnd.enable' => '0',
      'dnd.on_code' => '',
      'dnd.off_code' => '',
      }
  end

end
