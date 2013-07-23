class ExtensionModule < ActiveRecord::Base
  attr_accessible :model, :mac_address, :phone_id, :ip_address, :position, :active, :provisioning_key, :provisioning_key_active

  MODELS = ['snom_vision']

  belongs_to :phone
  before_save :remove_ip_address_when_mac_address_was_changed

  before_save :generate_key

  def to_s
    mac_address
  end

  def resync()
    if ! self.model == 'snom_vision'
      return false
    end

    http_user = nil
    http_password = nil
    
    if self.phone 
      http_user = self.phone.http_user
      http_password = self.phone.http_password
    end

    require 'open-uri'
    begin
      if open("http://#{self.ip_address}/ConfigurationModule/restart", :http_basic_authentication=>[http_user, http_password], :proxy => nil)
        return true
      end
    rescue
      return false
    end
  end

  private
  def sanitize_mac_address
    if self.mac_address.split(/:/).count == 6 && self.mac_address.length < 17
      splitted_mac_address = self.mac_address.split(/:/)
      self.mac_address = splitted_mac_address.map{|part| (part.size == 1 ? "0#{part}" : part)}.join('')
    end
    self.mac_address = self.mac_address.to_s.upcase.gsub( /[^A-F0-9]/, '' )
  end

  def remove_ip_address_when_mac_address_was_changed
    if self.mac_address_changed?
      self.ip_address = nil
    end
  end
  
  def generate_key
    if !GsParameter.get('PROVISIONING_KEY_LENGTH').nil? && GsParameter.get('PROVISIONING_KEY_LENGTH') > 0 && self.provisioning_key.blank?
      self.provisioning_key = SecureRandom.hex(GsParameter.get('PROVISIONING_KEY_LENGTH'))
    end
  end
end
