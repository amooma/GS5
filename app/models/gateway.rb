class Gateway < ActiveRecord::Base
  attr_accessible :name, :technology, :inbound, :outbound, :description

  has_many :gateway_settings, :dependent => :destroy
  has_many :gateway_parameters, :dependent => :destroy
end
