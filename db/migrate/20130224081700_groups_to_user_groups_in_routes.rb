class GroupsToUserGroupsInRoutes < ActiveRecord::Migration
  def up
    RouteElement.where(:var_in => 'val:auth_account.owner.groups').each do |route_element|
      route_element.update_attributes(:var_in => 'val:auth_account.owner.user_groups')
    end
    RouteElement.where(:var_in => 'val:account.owner.groups').each do |route_element|
      route_element.update_attributes(:var_in => 'val:account.owner.user_groups')
    end
  end

  def down
  	RouteElement.where(:var_in => 'val:auth_account.owner.user_groups').each do |route_element|
      route_element.update_attributes(:var_in => 'val:auth_account.owner.groups')
    end
    RouteElement.where(:var_in => 'val:account.owner.user_groups').each do |route_element|
      route_element.update_attributes(:var_in => 'val:account.owner.groups')
    end
  end
end
