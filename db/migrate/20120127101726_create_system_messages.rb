class CreateSystemMessages < ActiveRecord::Migration
  def self.up
    create_table :system_messages do |t|
      t.integer :user_id
      t.string :content
      t.timestamps
    end
  end

  def self.down
    drop_table :system_messages
  end
end
