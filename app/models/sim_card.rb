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

  def to_s
    self.sim_number.to_s
  end

  private
  def set_defaults 
    self.state ||= 'not activated'
  end

end
