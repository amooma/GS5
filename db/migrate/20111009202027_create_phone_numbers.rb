class CreatePhoneNumbers < ActiveRecord::Migration
  def self.up
    create_table :phone_numbers do |t|
      t.integer :phone_book_id
      t.string :name
      t.string :number
      t.string :country_code
      t.string :area_code
      t.string :subscriber_number
      t.string :extension
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_numbers
  end
end
