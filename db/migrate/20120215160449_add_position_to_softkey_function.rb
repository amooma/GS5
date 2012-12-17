class AddPositionToSoftkeyFunction < ActiveRecord::Migration
  def change
    add_column :softkey_functions, :position, :integer
    add_index :softkey_functions, :position
    add_index :softkey_functions, :name
  end
end
