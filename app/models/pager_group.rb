class PagerGroup < ActiveRecord::Base
  attr_accessible :sip_account_id, :callback_url

  has_many :pager_group_destinations, :dependent => :destroy
  belongs_to :sip_account

  validates_presence_of :sip_account_id 
end
