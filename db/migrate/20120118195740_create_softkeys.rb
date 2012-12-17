class CreateSoftkeys < ActiveRecord::Migration
  def self.up
    create_table :softkeys do |t|
      t.integer :phone_id
      t.string :name
      t.string :function
      t.string :number
      t.string :label
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :softkeys
  end
end
