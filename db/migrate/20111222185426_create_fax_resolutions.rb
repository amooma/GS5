class CreateFaxResolutions < ActiveRecord::Migration
  def change
    create_table :fax_resolutions do |t|
      t.string  :name
      t.string  :resolution_value
      t.integer :position

      t.timestamps
    end
  end
end
