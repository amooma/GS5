class CreateGemeinschaftSetups < ActiveRecord::Migration
  def self.up
    create_table :gemeinschaft_setups do |t|
      t.integer :tenant_id
      t.integer :user_id
      t.integer :sip_domain_id
      t.integer :default_extension_length
      t.integer :country_id
      t.integer :language_id
      t.string :human_area_code
      t.integer :area_code_id
      t.timestamps
    end
  end

  def self.down
    drop_table :gemeinschaft_setups
  end
end
