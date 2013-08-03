class CreateGatewayHeaders < ActiveRecord::Migration
  def self.up
    create_table :gateway_headers do |t|
      t.integer :gateway_id
      t.string :header_type
      t.string :constraint_source
      t.string :constraint_value
      t.string :name
      t.string :value
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_headers
  end
end
