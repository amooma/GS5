class CallForwardCase < ActiveRecord::Base
  
  attr_accessible :value
  
  has_many :call_forwards
  
  validates_presence_of :value
  
  def to_s
    self.value
  end
  
end
