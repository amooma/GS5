class AddPhoneticsToPhoneBookEntry < ActiveRecord::Migration
  def change
    add_column :phone_book_entries, :first_name_phonetic, :string
    add_column :phone_book_entries, :last_name_phonetic, :string
    add_column :phone_book_entries, :organization_phonetic, :string
  end
end
