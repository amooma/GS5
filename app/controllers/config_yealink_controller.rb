class ConfigYealinkController < ApplicationController

  MAX_SIP_ACCOUNTS = 5
  MAX_HANDSETS = 5
  MAX_PHONEBOOK_ENTRIES = 100
  MAX_PHONE_BOOKS = 5
  SIP_DEFAULT_PORT = 5060

  before_filter {
    @mac_address = params[:mac_address].to_s.upcase.gsub(/[^0-9A-F]/,'')
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
        @phone_books << {:name => phone_book.name, :url => "#{base_url}/#{phone_book.id}/phone_book.xml"}
        phone_book_ids[phone_book.id]
      end
      tenant = @phone.phoneable.current_tenant
    elsif @phone.phoneable.class == Tenant
      tenant = @phone.phoneable.class
    end

    if tenant
      tenant.phone_books.each do |phone_book|
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
      'anonymous_call_oncode' => 'f-cliron',
      'anonymous_call_offcode' => 'f-cliroff',
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
      'dnd.on_code' => 'f-dndon',
      'dnd.off_code' => 'f-dndoff',
      }
  end

end
