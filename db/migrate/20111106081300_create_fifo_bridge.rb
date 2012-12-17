class CreateFifoBridge < ActiveRecord::Migration
  def self.up
    create_table :fifo_bridge, :id => false do |t|
      t.string  :fifo_name,               :limit => '1024', :null => false
      t.string  :caller_uuid,             :limit => '255',  :null => false
      t.string  :caller_caller_id_name,   :limit => '255',  :null => false
      t.string  :caller_caller_id_number, :limit => '255',  :null => false
      t.string  :consumer_uuid,           :limit => '255',  :null => false
      t.string  :consumer_outgoing_uuid,  :limit => '255'
      t.integer :bridge_start
    end
  end

  def self.down
    drop_table :fifo_bridge
  end
end
