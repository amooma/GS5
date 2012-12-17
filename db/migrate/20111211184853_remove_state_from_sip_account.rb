class RemoveStateFromSipAccount < ActiveRecord::Migration
  def up
    remove_column :sip_accounts, :state
  end

  def down
    add_column :sip_accounts, :state, :string
  end
end
