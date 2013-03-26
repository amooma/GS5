class CreateVoicemailAccounts < ActiveRecord::Migration
  def self.up
    create_table :voicemail_accounts do |t|
      t.string :uuid
      t.string :name
      t.boolean :active
      t.integer :gs_node_id
      t.string :voicemail_accountable_type
      t.integer :voicemail_accountable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :voicemail_accounts
  end
end
