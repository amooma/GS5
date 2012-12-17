class AddStateToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :state, :string
  end
end
