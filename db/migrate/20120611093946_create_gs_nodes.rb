class CreateGsNodes < ActiveRecord::Migration
  def self.up
    create_table :gs_nodes do |t|
      t.string :name
      t.string :ip_address
      t.boolean :push_updates
      t.timestamps
    end
  end

  def self.down
    drop_table :gs_nodes
  end
end
