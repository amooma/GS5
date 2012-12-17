class CreateNat < ActiveRecord::Migration
  def self.up
    create_table :nat, :id => false do |t|
      t.integer :sticky
      t.integer :port
      t.integer :proto
      t.string  :hostname, :limit => '256'
    end
    add_index :nat, [ :port, :proto, :hostname ], :unique => false, :name => 'nat_map_port_proto'
  end

  def self.down
    drop_table :nat
  end
end
