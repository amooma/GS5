class CreateIntruders < ActiveRecord::Migration
  def self.up
    create_table :intruders do |t|
      t.string :list_type
      t.string :key
      t.integer :points
      t.integer :bans
      t.datetime :ban_last
      t.datetime :ban_end
      t.string :contact_ip
      t.integer :contact_port
      t.integer :contact_count
      t.datetime :contact_last
      t.float :contacts_per_second
      t.float :contacts_per_second_max
      t.string :user_agent
      t.string :to_user
      t.string :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :intruders
  end
end
