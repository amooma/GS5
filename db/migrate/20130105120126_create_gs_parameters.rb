class CreateGsParameters < ActiveRecord::Migration
  def self.up
    create_table :gs_parameters do |t|
      t.string :name
      t.string :section
      t.text :value
      t.string :class_type
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :gs_parameters
  end
end
