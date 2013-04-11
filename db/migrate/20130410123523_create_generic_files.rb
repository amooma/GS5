class CreateGenericFiles < ActiveRecord::Migration
  def self.up
    create_table :generic_files do |t|
      t.string :name
      t.string :file
      t.string :file_type
      t.string :category
      t.integer :owner_id
      t.string :owner_type
      t.timestamps
    end
  end

  def self.down
    drop_table :generic_files
  end
end
