class CreateSwitchboards < ActiveRecord::Migration
  def self.up
    create_table :switchboards do |t|
      t.string :name
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :switchboards
  end
end
