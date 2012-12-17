class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
      t.string :country_code
      t.string :international_call_prefix
      t.string :trunk_prefix

      t.timestamps
    end
  end
end
