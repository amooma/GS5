class CallRoute < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  ROUTING_TABLES = ['prerouting', 'outbound', 'inbound']

  has_many :route_elements, :dependent => :destroy

  validates :name,
  					:presence => true

  validates :routing_table,
            :presence => true,
            :inclusion => { :in => ROUTING_TABLES }

  acts_as_list :scope => '`routing_table` = \'#{routing_table}\''

  def to_s
    name.to_s
  end
end
