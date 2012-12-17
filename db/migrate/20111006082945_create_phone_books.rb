class CreatePhoneBooks < ActiveRecord::Migration
  def self.up
    create_table :phone_books do |t|
      t.string :name
      t.string :description
      t.integer :phone_bookable_id
      t.string :phone_bookable_type
      t.string :state
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_books
  end
end
