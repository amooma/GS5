class CreateGeoIpCountries < ActiveRecord::Migration
  def change
    create_table :geo_ip_countries do |t|
      t.string :from, :limit => '15'
      t.string :to, :limit => '15'
      t.integer :n_from
      t.integer :n_to
      t.integer :country_id
      t.string :country_code, :limit => '2'
      t.string :country_name, :limit => '64'

      t.timestamps
    end
  end
end
