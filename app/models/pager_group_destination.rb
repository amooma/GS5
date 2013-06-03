class PagerGroupDestination < ActiveRecord::Base
  attr_accessible :pager_group_id, :sip_account_id

  belongs_to :pager_group

  validates_presence_of :pager_group_id
  validates_presence_of :sip_account_id
end
