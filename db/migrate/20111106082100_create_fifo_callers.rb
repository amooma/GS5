class CreateFifoCallers < ActiveRecord::Migration
  def self.up
    create_table :fifo_callers, :id => false do |t|
      t.string  :fifo_name,               :limit => '255', :null => false
      t.string  :uuid,                    :limit => '255', :null => false
      t.string  :caller_caller_id_name,   :limit => '255'
      t.string  :caller_caller_id_number, :limit => '255'
      t.integer :timestamp
    end
  end

  def self.down
    drop_table :fifo_callers
  end
end
