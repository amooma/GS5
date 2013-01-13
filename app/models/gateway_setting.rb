class GatewaySetting < ActiveRecord::Base
  attr_accessible :gateway_id, :name, :value, :class_type, :description

  belongs_to :gateway
end
