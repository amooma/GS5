class AddValueOfToSToPhoneBookEntry < ActiveRecord::Migration
  def change
    add_column :phone_book_entries, :value_of_to_s, :string
  end
end
