class AddIsNativeToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :is_native, :boolean

  end
end
