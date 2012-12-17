class CreateFifoOutbound < ActiveRecord::Migration
  def self.up
    create_table :fifo_outbound, :id => false do |t|
      t.string  :uuid,                         :limit => '255'
      t.string  :fifo_name,                    :limit => '255'
      t.string  :originate_string,             :limit => '255'
      t.integer :simo_count
      t.integer :use_count
      t.integer :timeout
      t.integer :lag
      t.integer :next_avail,                   :null => false, :default => 0
      t.integer :expires,                      :null => false, :default => 0
      t.integer :static,                       :null => false, :default => 0
      t.integer :outbound_call_count,          :null => false, :default => 0
      t.integer :outbound_fail_count,          :null => false, :default => 0
      t.string  :hostname,                     :limit => '255'
      t.integer :taking_calls,                 :null => false, :default => 1
      t.string  :status,                       :limit => '255'
      t.integer :outbound_call_total_count,    :null => false, :default => 0
      t.integer :outbound_fail_total_count,    :null => false, :default => 0
      t.integer :active_time,                  :null => false, :default => 0
      t.integer :inactive_time,                :null => false, :default => 0
      t.integer :manual_calls_out_count,       :null => false, :default => 0
      t.integer :manual_calls_in_count,        :null => false, :default => 0
      t.integer :manual_calls_out_total_count, :null => false, :default => 0
      t.integer :manual_calls_in_total_count,  :null => false, :default => 0
      t.integer :ring_count,                   :null => false, :default => 0
      t.integer :start_time,                   :null => false, :default => 0
      t.integer :stop_time,                    :null => false, :default => 0
    end
  end

  def self.down
    drop_table :fifo_outbound
  end
end
