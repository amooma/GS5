class AddDefaultAreaCodeToGemeinschaftSetup < ActiveRecord::Migration
  def change
    add_column :gemeinschaft_setups, :default_area_code, :string
  end
end
