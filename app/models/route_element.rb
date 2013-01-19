class RouteElement < ActiveRecord::Base
  ELEMENT_ACTIONS = ['none', 'match', 'not_match', 'set']

  attr_accessible :call_route_id, :var_in, :var_out, :pattern, :replacement, :action, :mandatory, :position

  belongs_to :call_route

  acts_as_list :scope => :call_route

  validates :action,
            :presence => true,
            :inclusion => { :in => ELEMENT_ACTIONS }


  def to_s
    "#{pattern} => #{var_in} #{var_out}"
  end

end
