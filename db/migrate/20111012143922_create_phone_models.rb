class CreatePhoneModels < ActiveRecord::Migration
  def self.up
    create_table :phone_models do |t|
      t.string :name
      t.string :manufacturer_id
      t.string :product_manual_homepage_url
      t.string :product_homepage_url
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_models
  end
end
