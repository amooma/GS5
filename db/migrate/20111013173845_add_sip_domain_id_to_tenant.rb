class AddSipDomainIdToTenant < ActiveRecord::Migration
  def change
    add_column :tenants, :sip_domain_id, :integer
  end
end
