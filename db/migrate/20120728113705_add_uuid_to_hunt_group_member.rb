class AddUuidToHuntGroupMember < ActiveRecord::Migration
  def change
    add_column :hunt_group_members, :uuid, :string
    add_index :hunt_group_members, :uuid

  end
end
