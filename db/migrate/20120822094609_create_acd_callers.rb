class CreateAcdCallers < ActiveRecord::Migration
  def self.up
    create_table :acd_callers do |t|
      t.string :channel_uuid
      t.integer :automatic_call_distributor_id
      t.string :status
      t.datetime :enter_time
      t.datetime :agent_answer_time
      t.string :callback_number
      t.integer :callback_attempts
      t.timestamps
    end
  end

  def self.down
    drop_table :acd_callers
  end
end
