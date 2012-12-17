class AddCurrentTenantIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_tenant_id, :integer
  end
end
