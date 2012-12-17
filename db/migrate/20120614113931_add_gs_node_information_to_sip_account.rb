class AddGsNodeInformationToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :gs_node_id, :integer

    add_column :sip_accounts, :gs_node_original_id, :integer

  end
end
