class CreateRegistrations < ActiveRecord::Migration
  def self.up
    create_table :registrations, :id => false do |t|
      t.string  :reg_user
      t.string  :realm,         :limit => '256'
      t.string  :token,         :limit => '256'
      t.text    :url
      t.integer :expires
      t.string  :network_ip,    :limit => '256'
      t.string  :network_port,  :limit => '256'
      t.string  :network_proto, :limit => '256'
      t.string  :hostname,      :limit => '256'
    end
    add_index :registrations, [ :reg_user, :realm, :hostname ], :unique => false, :name => 'regindex1'
  end

  def self.down
    drop_table :registrations
  end
end
