class CreateAcdAgents < ActiveRecord::Migration
  def self.up
    create_table :acd_agents do |t|
      t.string :uuid
      t.string :name
      t.string :status
      t.integer :automatic_call_distributor_id
      t.datetime :last_call
      t.integer :calls_answered
      t.string :destination_type
      t.integer :destination_id
      t.timestamps
    end
  end

  def self.down
    drop_table :acd_agents
  end
end
