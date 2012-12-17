class CreateFaxPages < ActiveRecord::Migration
  def self.up
    create_table :fax_pages do |t|
      t.string :page
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :fax_pages
  end
end
