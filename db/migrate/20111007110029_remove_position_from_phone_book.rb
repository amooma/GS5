class RemovePositionFromPhoneBook < ActiveRecord::Migration
  def up
    remove_column :phone_books, :position
  end

  def down
    add_column :phone_books, :position, :integer
  end
end
