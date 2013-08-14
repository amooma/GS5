require 'scanf'

class Phone < ActiveRecord::Base
  
  attr_accessible :mac_address, :ip_address, :http_user, :http_password, 
                  :phone_model_id, :hot_deskable, :nightly_reboot,
                  :provisioning_key, :provisioning_key_active, :fallback_sip_account_id, :tenant
  
  # Associations
  #
  belongs_to :phone_model
  belongs_to :phoneable, :polymorphic => true, :touch => true

  has_many :phone_sip_accounts, :dependent => :destroy, :uniq => true, :order => :position
  has_many :sip_accounts, :through => :phone_sip_accounts

  has_many :extension_modules
  
  belongs_to :tenant
  belongs_to :fallback_sip_account, :class_name => "SipAccount"

  # Validations
  #
  before_validation :sanitize_mac_address
  before_validation :destroy_fallback_sip_account_if_not_hot_deskable
  
  validates_presence_of     :mac_address
  validate_mac_address      :mac_address
  validates_uniqueness_of   :mac_address
  
  validates_uniqueness_of   :ip_address,
    :if => Proc.new { |me| ! me.ip_address.blank? }
  validate_ip_address       :ip_address,
    :if => Proc.new { |me| ! me.ip_address.blank? }
  
  validates_presence_of     :phone_model
  validates_presence_of     :phoneable

  validates_uniqueness_of   :fallback_sip_account_id, :allow_nil => true
  
  before_save :save_last_ip_address
  before_save :destroy_phones_sip_accounts_if_phoneable_changed
  before_save :remove_ip_address_when_mac_address_was_changed
  
  # State machine:
  #
  default_scope where(:state => 'active')
  state_machine :initial => :active do
    
    event :deactivate do
      transition [:active] => :deactivated
    end
    
    event :activate do
      transition [:deactivated] => :active
    end
  end
  
  def to_s
    "%s %s %s" % [
      pretty_mac_address,
      "(#{self.phone_model})",
      self.ip_address ? "(#{self.ip_address})" : "",
    ]
  end
  
  def pretty_mac_address
    return [].fill('%02X', 0, 6).join(':') % self.mac_address.scanf( '%2X' * 6 )
  end


  def resync(reboot = false, sip_account = nil)
    if ! self.phone_model || ! self.phone_model.manufacturer
      return false
    end

    if self.phone_model.manufacturer.ieee_name == 'SNOM Technology AG'
      if !sip_account
        self.sip_accounts.where(:sip_accountable_type => self.phoneable_type).each do |sip_account_associated|
          if sip_account_associated.registration
            sip_account = sip_account_associated
            break
          end
        end
      end

      if ! sip_account or ! sip_account.registration
        require 'open-uri'
        begin
          if open("http://#{self.ip_address}/advanced_update.htm?reboot=Reboot", :http_basic_authentication=>[self.http_user, self.http_password], :proxy => nil)
            return true
          end
        rescue
          return false
        end
      end

      require 'freeswitch_event'
      event = FreeswitchEvent.new("NOTIFY")
      event.add_header("profile", "gemeinschaft")
      event.add_header("event-string", "check-sync;reboot=#{reboot.to_s}")
      event.add_header("user", sip_account.auth_name)
      event.add_header("host", sip_account.sip_domain.host)
      event.add_header("content-type", "application/simple-message-summary")   
      return event.fire()

    elsif self.phone_model.manufacturer.ieee_name == 'Siemens Enterprise CommunicationsGmbH & Co. KG'
      require 'open-uri'
      begin
        if open("http://#{self.ip_address}:8085/contact_dls.html/ContactDLS", :http_basic_authentication=>[self.http_user, self.http_password], :proxy => nil)
          return true
        end
      rescue
        return false
      end
    elsif self.phone_model.manufacturer.ieee_name == 'XIAMEN YEALINK NETWORK TECHNOLOGY CO.,LTD'
      if !sip_account
        self.sip_accounts.where(:sip_accountable_type => self.phoneable_type).each do |sip_account_associated|
          if sip_account_associated.registration
            sip_account = sip_account_associated
            break
          end
        end
      end

      if ! sip_account or ! sip_account.registration
        require 'open-uri'
        begin
          if open("http://#{self.ip_address}/cgi-bin/ConfigManApp.com?key=Reboot", :http_basic_authentication=>['admin', self.http_password], :proxy => nil)
            return true
          end
        rescue
          return false
        end
      end

      require 'freeswitch_event'
      event = FreeswitchEvent.new("NOTIFY")
      event.add_header("profile", "gemeinschaft")
      event.add_header("event-string", "check-sync;reboot=#{reboot.to_s}")
      event.add_header("user", sip_account.auth_name)
      event.add_header("host", sip_account.sip_domain.host)
      event.add_header("content-type", "application/simple-message-summary")   
      return event.fire()
    elsif self.phone_model.manufacturer.ieee_name == 'Polycom'
      if !sip_account
        self.sip_accounts.where(:sip_accountable_type => self.phoneable_type).each do |sip_account_associated|
          if sip_account_associated.registration
            sip_account = sip_account_associated
            break
          end
        end
      end

      if ! sip_account or ! sip_account.registration
        return false
      end

      require 'freeswitch_event'
      event = FreeswitchEvent.new("NOTIFY")
      event.add_header("profile", "gemeinschaft")
      event.add_header("event-string", "check-sync;reboot=#{reboot.to_s}")
      event.add_header("user", sip_account.auth_name)
      event.add_header("host", sip_account.sip_domain.host)
      event.add_header("content-type", "application/simple-message-summary")   
      return event.fire()
    end
      
    return false
  end


  # OPTIMIZE i18n translations
  def user_login(user, sip_account = nil)
    if ! self.hot_deskable
      errors.add(:hot_deskable, "Phone not hot-deskable")
      return false
    end

    phones_affected = Hash.new()
    sip_accounts = Array.new(1, sip_account)
    
    if !sip_account
      sip_accounts = user.sip_accounts.where(:hotdeskable => true).all
    end

    if sip_accounts.blank?
      errors.add(:sip_accounts, "No hot-deskable Sip Accounts available")
      return false
    end

    sip_account_resync = self.sip_accounts.where(:sip_accountable_type => self.phoneable_type).first

    phones_affected.each_pair do |id,phone|
      if phone.id != self.id
        phone.user_logout()
      end
    end

    PhoneSipAccount.where(:phone_id => self.id).destroy_all

    self.phoneable = user
    sip_accounts.each do |sip_account|
      if ! self.sip_accounts.where(:id => sip_account.id).first
        self.sip_accounts.push(sip_account)
      end
    end
    
    @not_destroy_phones_sip_accounts = true
    if ! self.save
      return false
    end
    
    sleep(0.5)

    if ! self.resync(true, sip_account_resync)
      errors.add(:resync, "Resync failed")
    end

    return true
  end


  # OPTIMIZE i18n translations
  def user_logout
    if ! self.hot_deskable
      errors.add(:hot_deskable, "Phone not hot-deskable")
      return false
    end

    sip_account = self.sip_accounts.where(:sip_accountable_type => self.phoneable_type).first

    if self.tenant
      self.phoneable = self.tenant
      if ! self.save
        errors.add(:phoneable, "Could not change owner")
        return false
      end
    end

    sleep(0.5)

    if ! self.resync(true, sip_account)
      errors.add(:resync, "Resync failed")
      return false
    end

    return true
  end

  private  
  # Sanitize MAC address.
  #
  def sanitize_mac_address
    if self.mac_address.split(/:/).count == 6 && self.mac_address.length < 17
      splitted_mac_address = self.mac_address.split(/:/)
      self.mac_address = splitted_mac_address.map{|part| (part.size == 1 ? "0#{part}" : part)}.join('')
    end
    self.mac_address = self.mac_address.to_s.upcase.gsub( /[^A-F0-9]/, '' )
  end
  
  # Saves the last IP address.
  #
  def save_last_ip_address
    if self.ip_address_changed? \
    && self.ip_address != self.ip_address_was
      self.last_ip_address = self.ip_address_was
    end
  end
  
  # When ever the parent of a phone changes all the SIP accounts associations
  # are destroyed unless this is a user logout operation
  #
  def destroy_phones_sip_accounts_if_phoneable_changed
    if (self.phoneable_type_changed? || self.phoneable_id_changed?) && ! @not_destroy_phones_sip_accounts
      self.phone_sip_accounts.destroy_all
    end
  end

  def remove_ip_address_when_mac_address_was_changed
    if self.mac_address_changed?
      self.ip_address = nil
      self.last_ip_address = nil
    end
  end

  def destroy_fallback_sip_account_if_not_hot_deskable
    if !self.hot_deskable?
      self.fallback_sip_account_id = nil
    end
  end
  
end
