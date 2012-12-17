class AddGsNodeInformationToHuntGroup < ActiveRecord::Migration
  def change
    add_column :hunt_groups, :gs_node_id, :integer

    add_column :hunt_groups, :gs_node_original_id, :integer

  end
end
