class AddIndexToPhoneBookEntry < ActiveRecord::Migration
  def change
    add_index :phone_book_entries, :first_name
    add_index :phone_book_entries, :last_name
    add_index :phone_book_entries, :organization
    add_index :phone_book_entries, :first_name_phonetic
    add_index :phone_book_entries, :last_name_phonetic
    add_index :phone_book_entries, :organization_phonetic
  end
end
