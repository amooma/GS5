class ParkingStall < ActiveRecord::Base
  attr_accessible :name, :lot, :parking_stallable_id, :parking_stallable_type, :comment

  belongs_to :parking_stallable, :polymorphic => true, :touch => true

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :lot,
            :presence => true

  def to_s
    name.to_s
  end

end
