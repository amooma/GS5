class CreateSwitchboardEntries < ActiveRecord::Migration
  def self.up
    create_table :switchboard_entries do |t|
      t.integer :switchboard_id
      t.integer :sip_account_id
      t.string :name
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :switchboard_entries
  end
end
