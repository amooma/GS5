class RouteElement < ActiveRecord::Base
  ELEMENT_ACTIONS = ['none', 'match', 'not_match', 'set']

  attr_accessible :call_route_id, :var_in, :var_out, :pattern, :replacement, :action, :mandatory, :position

  belongs_to :call_route, :touch => true

  acts_as_list :scope => :call_route

  validates :action,
            :presence => true,
            :inclusion => { :in => ELEMENT_ACTIONS }


  def to_s
    "#{pattern} => #{var_in} #{var_out}"
  end

  def move_up?
    #return self.position.to_i > RouteElement.where(:call_route_id => self.call_route_id ).order(:position).first.position.to_i
  end

  def move_down?
    #return self.position.to_i < RouteElement.where(:call_route_id => self.call_route_id ).order(:position).last.position.to_i
  end
end
