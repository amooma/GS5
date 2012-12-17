class AddCallWaitingToSipAccounts < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :call_waiting, :boolean
  end
end
