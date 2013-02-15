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

end
