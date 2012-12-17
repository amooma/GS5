class AddSipDomainIdToSipAccounts < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :sip_domain_id, :integer
  end
end
