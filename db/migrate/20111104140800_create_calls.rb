class CreateCalls < ActiveRecord::Migration
  def self.up
    create_table :calls, :id => false do |t|
      t.string :call_uuid,                     :limit=>'255', :primary => true
      t.string :call_created,                  :limit=>'128'
      t.integer :call_created_epoch
      t.string :function,                      :limit=>'1024'
      t.string :caller_cid_name,               :limit=>'1024'
      t.string :caller_cid_num,                :limit=>'256'
      t.string :caller_dest_num,               :limit=>'256'
      t.string :caller_chan_name,              :limit=>'1024'
      t.string :caller_uuid,                   :limit=>'256'
      t.string :callee_cid_name,               :limit=>'1024'
      t.string :callee_cid_numcallee_dest_num, :limit=>'256'
      t.string :callee_chan_name,              :limit=>'1024'
      t.string :callee_uuid,                   :limit=>'256'
      t.string :hostname,                      :limit=>'256'
    end
    add_index :calls, [ :hostname ],               :unique => false, :name => 'calls1'
    add_index :calls, [ :callee_uuid, :hostname ], :unique => false, :name => 'eeuuindex'
    add_index :calls, [ :call_uuid, :hostname ],   :unique => false, :name => 'eeuuindex2'
    add_index :calls, [ :caller_uuid, :hostname ], :unique => false, :name => 'eruuindex'
  end

  def self.down
    drop_table :calls
  end
end
