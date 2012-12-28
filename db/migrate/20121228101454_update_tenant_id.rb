class UpdateTenantId < ActiveRecord::Migration
  def up
    Phone.where(:hot_deskable => true).each do |phone|
      phone.tenant_id = Tenant.last.id
      phone.fallback_sip_account = phone.sip_accounts.where(:sip_accountable_type => 'Tenant').first
      phone.save
    end
  end

  def down
  end
end
