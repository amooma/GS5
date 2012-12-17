class CreatePhoneSipAccounts < ActiveRecord::Migration
  def self.up
    create_table :phone_sip_accounts do |t|
      t.integer :phone_id
      t.integer :sip_account_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_sip_accounts
  end
end
