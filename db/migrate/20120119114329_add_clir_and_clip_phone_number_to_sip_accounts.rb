class AddClirAndClipPhoneNumberToSipAccounts < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :clir, :boolean
    add_column :sip_accounts, :clip_phone_number_id, :integer
  end
end
