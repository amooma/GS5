class CallRoute < ActiveRecord::Base
  attr_accessible :table, :name, :endpoint_type, :endpoint_id, :position

  has_many :route_elements, :dependent => :destroy

  validates :name,
  					:presence => true

  acts_as_list :scope => '`table` = \'#{table}\''

  def to_s
    name.to_s
  end
end
