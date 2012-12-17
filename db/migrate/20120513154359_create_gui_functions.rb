class CreateGuiFunctions < ActiveRecord::Migration
  def self.up
    create_table :gui_functions do |t|
      t.string :category
      t.string :name
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :gui_functions
  end
end
