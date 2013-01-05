class CreateGsParameters < ActiveRecord::Migration
  def change
    create_table :gs_parameters do |t|
      t.string :name
      t.string :section
      t.string :value
      t.string :class_type

      t.timestamps
    end
  end
end
