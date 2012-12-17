class CreateAreaCodes < ActiveRecord::Migration
  def change
    create_table :area_codes do |t|
      t.integer :country_id
      t.string :name
      t.string :area_code

      t.timestamps
    end
  end
end
