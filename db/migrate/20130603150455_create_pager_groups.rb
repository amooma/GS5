class CreatePagerGroups < ActiveRecord::Migration
  def self.up
    create_table :pager_groups do |t|
      t.integer :sip_account_id
      t.string :callback_url
      t.timestamps
    end
  end

  def self.down
    drop_table :pager_groups
  end
end
