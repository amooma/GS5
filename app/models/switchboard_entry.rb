class SwitchboardEntry < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :switchboard, :touch => true
  belongs_to :sip_account, :touch => true

  has_many :phone_numbers, :through => :sip_account

  validates :switchboard,
            :presence => true

  validates :sip_account,
            :presence => true

  validates :name,
            :length => { :maximum => 10 },
            :uniqueness => {:scope => :switchboard_id},
            :allow_blank => true,
            :allow_nil => true

  acts_as_list :scope => [ :switchboard_id ]

  default_scope order(:position)

  def to_s
    if self.name.blank? && !self.sip_account.to_s.blank?
      self.sip_account.to_s
    else
      self.name.to_s
    end
  end
end
