class AddPolymorphicToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :phone_numberable_type, :string
    add_column :phone_numbers, :phone_numberable_id, :integer

    remove_column :phone_numbers, :phone_book_entry_id
  end
end
