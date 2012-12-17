class AddSoftkeyFunctionIdToSoftkey < ActiveRecord::Migration
  def change
    add_column :softkeys, :softkey_function_id, :integer
  end
end
