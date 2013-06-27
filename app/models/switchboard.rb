class Switchboard < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :user_id}

  validates :reload_interval,
            :numericality => { :only_integer => true, 
                               :greater_than => 249,
                               :allow_nil => true 
                             }

  validates :entry_width,
            :numericality => { :only_integer => true, 
                               :greater_than => 0,
                               :less_than => 5
                             }

  validates :amount_of_displayed_phone_numbers,
            :numericality => { :only_integer => true, 
                               :greater_than_or_equal_to => 0,
                               :less_than => 20
                             }

  belongs_to :user, :touch => true

  has_many :switchboard_entries, :dependent => :destroy
  has_many :switchable_switchboard_entries, :class_name => "SwitchboardEntry", :conditions => {:switchable => true}

  has_many :sip_accounts, :through => :switchboard_entries
  has_many :switchable_sip_accounts, :source => :sip_account, :through => :switchable_switchboard_entries, :uniq => true

  has_many :phone_numbers, :through => :sip_accounts

  before_validation :convert_0_to_nil

  def to_s
    self.name.to_s
  end

  def active_calls
    Call.where("sip_account_id = ? or b_sip_account_id = ?", self.switchable_sip_account_ids, self.switchable_sip_account_ids).order(:start_stamp)
  end

  def dispatchable_incoming_calls
    Call.where("b_sip_account_id = ?", self.switchable_sip_account_ids).order(:start_stamp)
  end

  private
  def convert_0_to_nil
    if self.reload_interval == 0
      self.reload_interval = nil
    end
  end
end
