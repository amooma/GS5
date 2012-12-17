class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :phone_book_entry_id
      t.string :line1
      t.string :line2
      t.string :street
      t.string :zip_code
      t.string :city
      t.integer :country_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
