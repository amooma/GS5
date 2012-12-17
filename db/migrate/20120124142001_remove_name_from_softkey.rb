class RemoveNameFromSoftkey < ActiveRecord::Migration
  def up
    remove_column :softkeys, :name
  end

  def down
    add_column :softkeys, :name, :string
  end
end
