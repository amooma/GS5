class AddLanguageIdToTenant < ActiveRecord::Migration
  def change
    add_column :tenants, :language_id, :integer
    add_column :tenants, :internal_extension_ranges, :string
    add_column :tenants, :did_list, :string
  end
end
