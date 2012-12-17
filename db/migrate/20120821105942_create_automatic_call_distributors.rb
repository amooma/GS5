class CreateAutomaticCallDistributors < ActiveRecord::Migration
  def self.up
    create_table :automatic_call_distributors do |t|
      t.string :uuid
      t.string :name
      t.string :strategy
      t.string :automatic_call_distributorable_type
      t.integer :automatic_call_distributorable_id
      t.integer :max_callers
      t.integer :agent_timeout
      t.integer :retry_timeout
      t.string :join
      t.string :leave
      t.integer :gs_node_id
      t.timestamps
    end
  end

  def self.down
    drop_table :automatic_call_distributors
  end
end
