class RemoveSipDomainIdFromSipAccount < ActiveRecord::Migration
  def up
    remove_column :sip_accounts, :sip_domain_id
  end

  def down
    add_column :sip_accounts, :sip_domain_id, :integer
  end
end
