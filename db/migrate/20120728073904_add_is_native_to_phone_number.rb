class AddIsNativeToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :is_native, :boolean

  end
end
