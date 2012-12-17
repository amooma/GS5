class Oui < ActiveRecord::Base
  attr_accessible :value
  
  validates_presence_of :manufacturer
  validates_presence_of :value
  
  belongs_to :manufacturer
  
  # State Machine stuff
  default_scope where(:state => 'active')
  state_machine :initial => :active do
  end
  
  def to_s
    value
  end
end
