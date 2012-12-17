class AddIsNativeToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_native, :boolean

  end
end
