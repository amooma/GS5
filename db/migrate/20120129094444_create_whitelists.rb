class CreateWhitelists < ActiveRecord::Migration
  def self.up
    create_table :whitelists do |t|
      t.string :name
      t.string :whitelistable_type
      t.integer :whitelistable_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :whitelists
  end
end
