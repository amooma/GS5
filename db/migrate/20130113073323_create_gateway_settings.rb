class CreateGatewaySettings < ActiveRecord::Migration
  def self.up
    create_table :gateway_settings do |t|
      t.integer :gateway_id
      t.string :name
      t.string :value
      t.string :class_type
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_settings
  end
end
