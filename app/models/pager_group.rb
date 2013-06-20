class PagerGroup < ActiveRecord::Base
  attr_accessible :sip_account_id, :callback_url
  attr_writer :pager_group_destination_ids

  has_many :pager_group_destinations, :dependent => :destroy
  belongs_to :sip_account

  validates_presence_of :sip_account_id

  after_create :call
  before_destroy :hangup_all

  before_save :save_pager_group_destination_ids

  def save_pager_group_destination_ids
    if @pager_group_destination_ids
      self.pager_group_destination_ids = @pager_group_destination_ids.split(/,/).map { |sip_account_id| self.pager_group_destinations.build(:sip_account_id => sip_account_id) }
    end
  end

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
