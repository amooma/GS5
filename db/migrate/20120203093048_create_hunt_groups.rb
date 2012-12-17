class CreateHuntGroups < ActiveRecord::Migration
  def self.up
    create_table :hunt_groups do |t|
      t.integer :tenant_id
      t.string :name
      t.string :strategy
      t.integer :seconds_between_jumps
      t.timestamps
    end
  end

  def self.down
    drop_table :hunt_groups
  end
end
