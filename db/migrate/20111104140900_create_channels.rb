class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels, :id => false do |t|
      t.string :uuid,             :limit=>'256', :primary => true
      t.string :direction,        :limit=>'32'
      t.string :created,          :limit=>'128'
      t.integer :created_epoch
      t.string :name,             :limit=>'1024'
      t.string :state,            :limit=>'64'
      t.string :cid_name,         :limit=>'1024'
      t.string :cid_num,          :limit=>'256'
      t.string :ip_addr,          :limit=>'256'
      t.string :dest,             :limit=>'1024'
      t.string :application,      :limit=>'128'
      t.string :application_data, :limit=>'4096'
      t.string :dialplan,         :limit=>'128'
      t.string :context,          :limit=>'128'
      t.string :read_codec,       :limit=>'128'
      t.string :read_rate,        :limit=>'32'
      t.string :read_bit_rate,    :limit=>'32'
      t.string :write_codec,      :limit=>'128'
      t.string :write_rate,       :limit=>'32'
      t.string :write_bit_rate,   :limit=>'32'
      t.string :secure,           :limit=>'32'
      t.string :hostname,         :limit=>'256'
      t.string :presence_id,      :limit=>'4096'
      t.string :presence_data,    :limit=>'4096'
      t.string :callstate,        :limit=>'64'
      t.string :callee_name,      :limit=>'1024'
      t.string :callee_num,       :limit=>'256'
      t.string :callee_direction, :limit=>'5'
      t.string :call_uuid,        :limit=>'256'
    end
    add_index :channels, [ :hostname ],             :unique => false, :name => 'channels1'
    add_index :channels, [ :uuid, :hostname ],      :unique => true,  :name => 'uuindex'
    add_index :channels, [ :call_uuid, :hostname ], :unique => false, :name => 'uuindex2'
  end

  def self.down
    drop_table :channels
  end
end
