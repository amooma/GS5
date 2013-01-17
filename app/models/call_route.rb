class CallRoute < ActiveRecord::Base
  ROUTING_TABLES = ['prerouting', 'outbound', 'inbound']

  attr_accessible :table, :name, :endpoint_type, :endpoint_id, :position

  has_many :route_elements, :dependent => :destroy

  validates :name,
  					:presence => true

  validates :table,
            :presence => true,
            :inclusion => { :in => ROUTING_TABLES }

  acts_as_list :scope => '`table` = \'#{table}\''

  def to_s
    name.to_s
  end
end
