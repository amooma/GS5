class CreateCallForwardCases < ActiveRecord::Migration
  
  def self.up
    create_table :call_forward_cases do |t|
      t.string :value
      t.timestamps
    end
    add_index( :call_forward_cases, :value, {
      :name => "call_forward_cases_value_index",
      :unique => true,
    })
  end

  def self.down
    remove_index( :call_forward_cases, {
      :name => "call_forward_cases_value_index",
    })
    drop_table :call_forward_cases
  end
  
end
