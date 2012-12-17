class AddPinToUser < ActiveRecord::Migration
  def change
    add_column :users, :pin_salt, :string
    add_column :users, :pin_hash, :string
  end
end
