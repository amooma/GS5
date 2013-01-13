class GatewaySetting < ActiveRecord::Base
  attr_accessible :gateway_id, :name, :value, :class_type, :description

  belongs_to :gateway

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :gateway_id}

  validates :class_type,
            :presence => true,
            :inclusion => { :in => ['String', 'Integer', 'Boolean'] }

  def to_s
  	name
  end
end
