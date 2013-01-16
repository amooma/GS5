class RouteElement < ActiveRecord::Base
  attr_accessible :call_route_id, :var_in, :var_out, :pattern, :replacement, :action, :mandatory, :position

  belongs_to :call_route
end
