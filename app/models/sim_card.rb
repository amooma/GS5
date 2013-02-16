class SimCard < ActiveRecord::Base
  attr_accessible :auto_order_card, :sip_account_id, :auth_key, :sim_number

  # Validations
  #
  validates :sim_card_provider_id,
            :presence => true

  belongs_to :sim_card_provider, :touch => true

  validates :sim_card_provider,
            :presence => true

  validates :sip_account_id,
            :presence => true            

  belongs_to :sip_account

  validates :sip_account,
            :presence => true            

  validates :sim_number,
            :presence => true

  after_initialize :set_defaults

  before_validation :upcase_some_values
  after_create :active_sim_card

  def to_s
    self.sim_number.to_s
  end

  private
  def set_defaults 
    self.state ||= 'not activated'
  end

  def upcase_some_values
    self.sim_number = self.sim_number.to_s.upcase
  end

  def active_sim_card
    require 'open-uri'

    url = "#{self.sim_card_provider.api_server_url}/app/api/main?cmd=order&ref=#{self.sim_number}&s=#{self.sim_card_provider.sip_server}&u=#{self.sip_account.auth_name}&p=#{self.sip_account.password}&ordercard=0&apiuser=#{self.sim_card_provider.api_username}&apipass=#{self.sim_card_provider.api_password}"

    open(url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
        "From" => "admin@localhost",
        "Referer" => "http://amooma.com/gemeinschaft/gs5") { |f|
        # Save the response body
        @response = f.read
    }

    if @response.class == String && @response.split(/;/).first == 'OK'
      self.state = 'activated'
      self.auth_key = @response.split(/;/).last.chomp.split(/=/).last
      self.save
    end

  end

end
