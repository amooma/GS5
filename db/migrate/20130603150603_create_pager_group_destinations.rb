class CreatePagerGroupDestinations < ActiveRecord::Migration
  def self.up
    create_table :pager_group_destinations do |t|
      t.integer :pager_group_id
      t.integer :sip_account_id
      t.timestamps
    end
  end

  def self.down
    drop_table :pager_group_destinations
  end
end
