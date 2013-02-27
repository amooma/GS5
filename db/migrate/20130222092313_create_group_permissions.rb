class CreateGroupPermissions < ActiveRecord::Migration
  def self.up
    create_table :group_permissions do |t|
      t.integer :group_id
      t.string :permission
      t.integer :target_group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :group_permissions
  end
end
