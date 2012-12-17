class PhoneSipAccount < ActiveRecord::Base
  attr_accessible :sip_account_id
  
  belongs_to :phone
  belongs_to :sip_account
  
  validates_presence_of :phone
  validates_presence_of :sip_account

  validates_uniqueness_of :sip_account_id, :scope => :phone_id
  
  acts_as_list :scope => :phone
  
  def to_s
    "Position #{self.position}"
  end
end
