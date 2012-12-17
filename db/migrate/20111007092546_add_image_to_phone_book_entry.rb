class AddImageToPhoneBookEntry < ActiveRecord::Migration
  def change
    add_column :phone_book_entries, :image, :string
  end
end
