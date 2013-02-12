class CreateParkingStalls < ActiveRecord::Migration
  def self.up
    create_table :parking_stalls do |t|
      t.string :name
      t.string :lot
      t.integer :parking_stallable_id
      t.string :parking_stallable_type
      t.string :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :parking_stalls
  end
end
