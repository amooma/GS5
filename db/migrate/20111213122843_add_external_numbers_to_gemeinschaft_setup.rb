class AddExternalNumbersToGemeinschaftSetup < ActiveRecord::Migration
  def change
    add_column :gemeinschaft_setups, :external_numbers, :string
  end
end
