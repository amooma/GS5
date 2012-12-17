class CreateUserGroups < ActiveRecord::Migration
  def self.up
    create_table :user_groups do |t|
      t.string :name
      t.text :description
      t.integer :tenant_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :user_groups
  end
end
