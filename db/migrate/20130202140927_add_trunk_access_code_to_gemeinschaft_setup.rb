class AddTrunkAccessCodeToGemeinschaftSetup < ActiveRecord::Migration
  def change
    add_column :gemeinschaft_setups, :trunk_access_code, :string
  end
end
