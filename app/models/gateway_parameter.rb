class GatewayParameter < ActiveRecord::Base
  attr_accessible :gateway_id, :name, :value, :class_type, :description

  belongs_to :gateway

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :class_type,
            :presence => true,
            :inclusion => { :in => ['String', 'Integer', 'Boolean'] }
end
