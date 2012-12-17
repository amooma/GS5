class CreateFaxes < ActiveRecord::Migration
  def self.up
    create_table :faxes do |t|
      t.boolean :inbound
      t.string :pdf
      t.integer :faxable_id
      t.string :faxable_type
      t.string :state
      t.integer :number_of_pages
      t.integer :transmission_time
      t.datetime :sent_at
      t.timestamps
    end
  end

  def self.down
    drop_table :faxes
  end
end
