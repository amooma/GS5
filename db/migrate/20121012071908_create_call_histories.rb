class CreateCallHistories < ActiveRecord::Migration
  def change
    create_table :call_histories do |t|
      t.string :call_historyable_type
      t.integer :call_historyable_id
      t.string :entry_type
      t.string :caller_account_type
      t.integer :caller_account_id
      t.string :caller_id_number
      t.string :caller_id_name
      t.string :caller_channel_uuid
      t.string :callee_account_type
      t.integer :callee_account_id
      t.string :callee_id_number
      t.string :callee_id_name
      t.string :auth_account_type
      t.integer :auth_account_id
      t.string :forwarding_service
      t.string :destination_number
      t.datetime :start_stamp
      t.integer :duration
      t.string :result
      t.boolean :read_flag
      t.boolean :returned_flag
      
      t.timestamps
    end
  end
end
