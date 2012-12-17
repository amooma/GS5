class CreateCdrs < ActiveRecord::Migration
  def self.up
    create_table :cdrs, :id => false do |t|
      t.string   :uuid,                    :limit => '256', :primary => true
      t.integer  :account_id
      t.string   :account_type,            :limit => '256'
      t.string   :bleg_uuid,               :limit => '256'
      t.integer  :bleg_account_id
      t.string   :bleg_account_type,       :limit => '256'
      t.string   :dialed_number,           :limit => '256'
      t.string   :destination_number,      :limit => '256'
      t.string   :caller_id_number,        :limit => '256'
      t.string   :caller_id_name,          :limit => '256'
      t.string   :callee_id_number,        :limit => '256'
      t.string   :callee_id_name,          :limit => '256'
      t.datetime :start_stamp
      t.datetime :answer_stamp
      t.datetime :end_stamp
      t.integer  :duration
      t.integer  :billsec
      t.string   :hangup_cause,            :limit => '256'
      t.string   :dialstatus,              :limit => '256'
      t.string   :forwarding_number,       :limit => '256'
      t.integer  :forwarding_account_id
      t.string   :forwarding_account_type, :limit => '256'
      t.string   :forwarding_service,      :limit => '256'
    end
  end

  def self.down
    drop_table :cdrs
  end
end
