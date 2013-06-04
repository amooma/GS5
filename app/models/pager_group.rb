class PagerGroup < ActiveRecord::Base
  attr_accessible :sip_account_id, :callback_url

  has_many :pager_group_destinations, :dependent => :destroy
  belongs_to :sip_account

  validates_presence_of :sip_account_id

  after_create :call
  before_destroy :hangup_all

  def identifier
    "pager#{self.id}"
  end

  def call
    self.sip_account.call("f-pager-#{self.id}")
  end

  def hangup_all
    require 'freeswitch_event'
    return FreeswitchAPI.execute(
      'conference', "#{self.identifier} hup all", 
      true
    );
  end
end
