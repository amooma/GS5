class RouteElement < ActiveRecord::Base
  ELEMENT_ACTIONS = ['match', 'not_match', 'set_route_var', 'set_header']

  attr_accessible :call_route_id, :var_in, :var_out, :pattern, :replacement, :action, :mandatory, :position

  belongs_to :call_route

  acts_as_list :scope => :call_route

  validates :var_in,
            :presence => true

  validates :pattern,
            :presence => true

  validates :action,
            :presence => true,
            :inclusion => { :in => ELEMENT_ACTIONS }


  def to_s
    "#{var_in} #{var_out}"
  end

end
