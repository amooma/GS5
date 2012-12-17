class SipDomain < ActiveRecord::Base
  attr_accessible :host, :realm
  
  has_many :tenants, :dependent => :restrict
  has_many :sip_accounts, :dependent => :restrict
  
  validates_presence_of   :host
  validates_uniqueness_of :host, :case_sensitive => false
  
  validates_presence_of   :realm
  validates_uniqueness_of :realm
  
  def to_s
    self.host
  end
end
