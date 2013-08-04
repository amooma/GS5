class GatewayHeader < ActiveRecord::Base
  HEADER_TYPES = [
    'default',
    'invite', 
  #  'provisional', 
  # 'request', 
  #  'bye',
  ]

  attr_accessible :gateway_id, :header_type, :constraint_source, :constraint_value, :name, :value, :description

  belongs_to :gateway, :touch => true

  validates :name,
            :presence => true,
            :uniqueness => {:scope => [:gateway_id, :header_type, :constraint_source, :constraint_value]}

  validates :header_type,
            :presence => true,
            :inclusion => { :in => HEADER_TYPES }

  def to_s
  	name
  end
end
