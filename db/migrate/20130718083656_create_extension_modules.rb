class CreateExtensionModules < ActiveRecord::Migration
  def self.up
    create_table :extension_modules do |t|
      t.string :model
      t.string :mac_address
      t.string :ip_address
      t.string :provisioning_key
      t.boolean :provisioning_key_active
      t.integer :phone_id
      t.integer :position
      t.boolean :active
      t.timestamps
    end
  end

  def self.down
    drop_table :extension_modules
  end
end
