class CreateSipAccounts < ActiveRecord::Migration
  def self.up
    create_table :sip_accounts do |t|
      t.string :sip_accountable_type
      t.integer :sip_accountable_id
      t.string :auth_name
      t.string :caller_name
      t.string :password
      t.string :voicemail_pin
      t.string :state
      t.timestamps
    end
  end

  def self.down
    drop_table :sip_accounts
  end
end
