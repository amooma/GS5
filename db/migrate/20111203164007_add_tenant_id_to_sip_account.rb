class AddTenantIdToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :tenant_id, :integer
  end
end
