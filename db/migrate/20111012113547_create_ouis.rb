class CreateOuis < ActiveRecord::Migration
  def change
    create_table :ouis do |t|
      t.integer :manufacturer_id
      t.string :value
      t.string :state

      t.timestamps
    end
  end
end
