class CreatePhoneNumberRanges < ActiveRecord::Migration
  def self.up
    create_table :phone_number_ranges do |t|
      t.integer :tenant_id
      t.string :name
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_number_ranges
  end
end
