class CallRoute < ActiveRecord::Base
  attr_accessible :table, :name, :endpoint_type, :endpoint_id, :position
end
