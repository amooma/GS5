class AddTenantToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :tenant_id, :integer

  end
end
