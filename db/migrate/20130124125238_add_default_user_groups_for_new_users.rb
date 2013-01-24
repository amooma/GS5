class AddDefaultUserGroupsForNewUsers < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'DEFAULT_USER_GROUPS_IDS', :section => 'New user defaults', :value => "---\n- 3\n", :class_type => 'YAML', :description => 'Default user group ids for a new user.')
  end

  def down
  	GsParameter.where(:name => 'DEFAULT_USER_GROUPS_IDS').destroy_all
  end
end
