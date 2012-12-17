class AddCountryIdToTenant < ActiveRecord::Migration
  def change
    add_column :tenants, :country_id, :integer
  end
end
