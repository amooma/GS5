class Gateway < ActiveRecord::Base
  TECHNOLOGIES = ['sip', 'xmpp']
  GATEWAY_PREFIX = 'gateway'

  attr_accessible :name, :technology, :inbound, :outbound, :description

  has_many :gateway_settings, :dependent => :destroy
  has_many :gateway_parameters, :dependent => :destroy
  has_many :call_routes, :as => :endpoint, :dependent => :nullify

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :technology,
            :presence => true,
            :inclusion => { :in => TECHNOLOGIES }

  after_initialize :set_defaults
  before_validation :downcase_technology

  after_create :create_default_settings

  def to_s
    name
  end

  def identifier
    "#{GATEWAY_PREFIX}#{self.id}"
  end

  def status
    if self.technology == 'sip' then
      return status_sip
    end
  end

  def inbound_register
    username = self.gateway_settings.where(:name => 'inbound_username').first.try(:value)
    if username.blank?
      return
    end

    return SipRegistration.where(:sip_user => username).first
  end

  private
  def status_sip
    require 'freeswitch_event'
    result = FreeswitchAPI.api_result(FreeswitchAPI.api('sofia', 'xmlstatus', 'gateway', "gateway#{self.id}"))
    if result =~ /^\<\?xml/
      data = Hash.from_xml(result)
      if data
        return data.fetch('gateway', nil)
      end
    end
    return nil
  end

  def downcase_technology
    self.technology = self.technology.downcase if !self.technology.blank?
  end

  def set_defaults 
    if TECHNOLOGIES.count == 1
      self.technology = TECHNOLOGIES.first
    end
  end

  def create_default_settings
    if self.technology == 'sip' then
      GsParameter.where(:entity => 'sip_gateways', :section => 'settings').each do |default_setting|
        self.gateway_settings.create(:name => default_setting.name, :value => default_setting.value, :class_type => default_setting.class_type, :description => default_setting.description)
      end
    end
  end

end
