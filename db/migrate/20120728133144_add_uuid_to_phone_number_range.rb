class AddUuidToPhoneNumberRange < ActiveRecord::Migration
  def change
    add_column :phone_number_ranges, :uuid, :string
    add_index :phone_number_ranges, :uuid

  end
end
