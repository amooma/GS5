class CreateTenants < ActiveRecord::Migration
  def self.up
    create_table :tenants do |t|
      t.string :name
      t.text :description
      t.string :state
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :tenants
  end
end
