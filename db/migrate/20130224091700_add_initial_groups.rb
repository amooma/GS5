class AddInitialGroups < ActiveRecord::Migration
  def up
    Group.create(:name => 'admins', :active => true, :comment => 'Administrator user accounts')
    Group.create(:name => 'users', :active => true, :comment => 'Generic user accounts')
    Group.create(:name => 'tenant_sip_accounts', :active => true, :comment => 'SIP accounts owned by tenants')

    user_sip_accounts = Group.create(:name => 'user_sip_accounts', :active => true, :comment => 'SIP accounts owned by user accounts')
    user_sip_accounts.group_permissions.create(:permission => 'pickup', :target_group_id => user_sip_accounts.id)
    user_sip_accounts.group_permissions.create(:permission => 'presence', :target_group_id => user_sip_accounts.id)

    Group.create(:name => 'international_calls', :active => true, :comment => 'International calls permitted')
    Group.create(:name => 'national_calls', :active => true, :comment => 'National calls permitted')

    GsParameter.create(:entity => 'group', :section => 'default', :name => 'User.admin',  :value => '--- [admins]\n', :class_type => 'YAML')
    GsParameter.create(:entity => 'group', :section => 'default', :name => 'User',  :value => '--- [users]\n', :class_type => 'YAML')
    GsParameter.create(:entity => 'group', :section => 'default', :name => 'SipAccount.user',  :value => '--- [user_sip_accounts, international_calls, national_calls]\n', :class_type => 'YAML')
    GsParameter.create(:entity => 'group', :section => 'default', :name => 'SipAccount.tenant',  :value => '--- [tenant_sip_accounts]\n', :class_type => 'YAML')
  end

  def down
  	Group.destroy_all
  end
end
