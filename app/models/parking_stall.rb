class ParkingStall < ActiveRecord::Base
  attr_accessible :name, :lot, :parking_stallable_id, :parking_stallable_type, :comment
end
