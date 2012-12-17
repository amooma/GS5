class AddUuidToPhoneBookEntry < ActiveRecord::Migration
  def change
    add_column :phone_book_entries, :uuid, :string
    add_index :phone_book_entries, :uuid

  end
end
