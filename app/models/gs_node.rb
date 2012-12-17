class GsNode < ActiveRecord::Base
  attr_accessible :name, :ip_address, :site, :element_name, :push_updates_to, :accepts_updates_from

  has_many :phone_numbers, :foreign_key => :gs_node_id, :dependent => :destroy
  has_many :users, :foreign_key => :gs_node_id, :dependent => :destroy
  has_many :sip_accounts, :foreign_key => :gs_node_id, :dependent => :destroy
  has_many :hunt_groups, :foreign_key => :gs_node_id, :dependent => :destroy

  validates :name,
            :presence => true

  validates :ip_address,
            :presence => true

  validates :site,
            :presence => true

  validates :element_name,
            :presence => true

  def to_s
    name
  end

  def synced
    self.last_sync = Time.now
    return self.save
  end

end
