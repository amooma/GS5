class AddUuidToPhoneBooks < ActiveRecord::Migration
  def change
    add_column :phone_books, :uuid, :string

  end
end
