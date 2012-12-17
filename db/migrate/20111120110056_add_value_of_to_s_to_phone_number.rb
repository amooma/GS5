class AddValueOfToSToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :value_of_to_s, :string
    add_column :sip_accounts, :value_of_to_s, :string
  end
end
