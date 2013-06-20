class AddVoicemailAccountIdToSipAccounts < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :voicemail_account_id, :integer
  end
end
