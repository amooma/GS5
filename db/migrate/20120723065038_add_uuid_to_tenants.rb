class AddUuidToTenants < ActiveRecord::Migration
  def change
    add_column :tenants, :uuid, :string

  end
end
