class AddTenantIdToFaxAccount < ActiveRecord::Migration
  def change
    add_column :fax_accounts, :tenant_id, :integer
    add_column :fax_accounts, :station_id, :string
  end
end
