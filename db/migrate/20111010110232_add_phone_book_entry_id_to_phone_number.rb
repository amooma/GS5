class AddPhoneBookEntryIdToPhoneNumber < ActiveRecord::Migration
  def change
    remove_column :phone_numbers, :phone_book_id
    add_column :phone_numbers, :phone_book_entry_id, :integer
  end
end
