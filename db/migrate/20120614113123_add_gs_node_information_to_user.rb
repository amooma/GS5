class AddGsNodeInformationToUser < ActiveRecord::Migration
  def change
    add_column :users, :gs_node_id, :integer

    add_column :users, :gs_node_original_id, :integer

  end
end
