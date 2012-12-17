class CreateCallForwards < ActiveRecord::Migration
  
  def self.up
    create_table :call_forwards do |t|
      t.integer :sip_account_id
      t.integer :call_forward_case_id
      t.integer :timeout
      t.string :destination
      t.string :source
      t.boolean :active
      t.timestamps
    end
    add_index( :call_forwards, :sip_account_id, {
      :name => "call_forwards_sip_account_index",
    })
  end

  def self.down
    remove_index( :call_forwards, {
      :name => "call_forwards_sip_account_index",
    })
    drop_table :call_forwards
  end
  
end
