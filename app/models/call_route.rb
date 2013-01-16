class CallRoute < ActiveRecord::Base
  attr_accessible :table, :name, :endpoint_type, :endpoint_id, :position

  has_many :route_elements, :dependent => :destroy
end
