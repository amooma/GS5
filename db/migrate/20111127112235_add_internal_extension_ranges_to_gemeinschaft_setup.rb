class AddInternalExtensionRangesToGemeinschaftSetup < ActiveRecord::Migration
  def change
    add_column :gemeinschaft_setups, :internal_extension_ranges, :string
    remove_column :gemeinschaft_setups, :default_extension_length
  end
end
