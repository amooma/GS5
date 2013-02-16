class SimCardProvider < ActiveRecord::Base
  attr_accessible :name, :homepage_url, :docu_url, :api_server_url, :api_username, :api_password, :ref, :sip_server, :include_order_card_function

  # Validations
  #
  validates :name,
      :presence => true,
      :uniqueness => true

  validates :api_username,
      :presence => true
      
  validates :api_password,
      :presence => true

  validates :api_server_url,
      :presence => true

  validates :sip_server,
      :presence => true

  has_many :sim_cards, :dependent => :destroy

  def to_s
    name.to_s
  end

end
