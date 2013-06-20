class PagerGroupDestination < ActiveRecord::Base
  attr_accessible :pager_group_id, :sip_account_id

  belongs_to :pager_group
  belongs_to :sip_account

  validates_presence_of :pager_group_id
  validates_presence_of :sip_account_id

  after_create :call

  def call
    self.sip_account.call("f-pager-#{self.pager_group_id}", '', "Pager #{self.id}")
  end
end
