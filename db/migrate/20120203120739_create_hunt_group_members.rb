class CreateHuntGroupMembers < ActiveRecord::Migration
  def self.up
    create_table :hunt_group_members do |t|
      t.integer :hunt_group_id
      t.string :name
      t.integer :position
      t.boolean :active
      t.boolean :can_switch_status_itself
      t.timestamps
    end
  end

  def self.down
    drop_table :hunt_group_members
  end
end
