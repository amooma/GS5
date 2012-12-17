class AddCentralOfficeCodeToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :central_office_code, :string
  end
end
