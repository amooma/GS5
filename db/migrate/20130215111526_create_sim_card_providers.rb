class CreateSimCardProviders < ActiveRecord::Migration
  def self.up
    create_table :sim_card_providers do |t|
      t.string :name
      t.string :homepage_url
      t.string :docu_url
      t.string :api_server_url
      t.string :api_username
      t.string :api_password
      t.string :ref
      t.string :sip_server
      t.boolean :include_order_card_function
      t.timestamps
    end
  end

  def self.down
    drop_table :sim_card_providers
  end
end
