class CreateSoftkeyFunctions < ActiveRecord::Migration
  def up
    create_table :softkey_functions do |t|
      t.string :name

      t.timestamps
    end

  end

  def down
    drop_table :softkey_functions
  end
end
