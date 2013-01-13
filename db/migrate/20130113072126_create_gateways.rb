class CreateGateways < ActiveRecord::Migration
  def self.up
    create_table :gateways do |t|
      t.string :name
      t.string :technology
      t.boolean :inbound
      t.boolean :outbound
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :gateways
  end
end
