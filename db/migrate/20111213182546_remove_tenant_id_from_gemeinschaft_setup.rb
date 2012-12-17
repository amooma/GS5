class RemoveTenantIdFromGemeinschaftSetup < ActiveRecord::Migration
  def up
    remove_column :gemeinschaft_setups, :tenant_id
    remove_column :gemeinschaft_setups, :human_area_code
    remove_column :gemeinschaft_setups, :area_code_id
    remove_column :gemeinschaft_setups, :internal_extension_ranges
    remove_column :gemeinschaft_setups, :external_numbers
  end

  def down
    add_column :gemeinschaft_setups, :external_numbers, :string
    add_column :gemeinschaft_setups, :internal_extension_ranges, :string
    add_column :gemeinschaft_setups, :area_code_id, :integer
    add_column :gemeinschaft_setups, :human_area_code, :string
    add_column :gemeinschaft_setups, :tenant_id, :integer
  end
end
