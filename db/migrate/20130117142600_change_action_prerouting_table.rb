class ChangeActionPreroutingTable < ActiveRecord::Migration
  def up
    RouteElement.where(:action => 'set_route_var', :mandatory => true).each do |route|
      route.update_attributes(:action => 'match')
    end
  end

  def down
  	RouteElement.where(:action => 'match', :mandatory => true).each do |route|
      route.update_attributes(:action => 'set_route_var')
    end
  end
end
