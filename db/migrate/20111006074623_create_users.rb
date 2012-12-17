class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :user_name
      t.string :email
      t.string :password_digest
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.boolean :male
      t.string :gemeinschaft_unique_id
      t.string :state
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
