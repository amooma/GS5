class AddPresencePermissionToGroups < ActiveRecord::Migration
  def up
    user_sip_accounts = Group.where(:name => 'user_sip_accounts').first
    if user_sip_accounts
      user_sip_accounts.group_permissions.create(:permission => 'presence', :target_group_id => user_sip_accounts.id)
    end
  end

  def down
  end
end
