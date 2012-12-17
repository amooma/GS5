class RenameColumnsOfPhoneNumberRange < ActiveRecord::Migration
  def change
    # I'm not going to revert all existing entries here.
    add_column :phone_number_ranges, :phone_number_rangeable_type, :string
    add_column :phone_number_ranges, :phone_number_rangeable_id, :integer
    remove_column :phone_number_ranges, :tenant_id
  end
end
