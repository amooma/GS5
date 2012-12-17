class AddGsNodeIdToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :gs_node_id, :integer

    add_column :phone_numbers, :gs_node_original_id, :integer

  end
end
