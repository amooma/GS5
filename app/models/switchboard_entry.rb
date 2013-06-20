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

  def avatar_src
    if self.sip_account.sip_accountable.class == User
      if self.sip_account.sip_accountable.image?
        self.sip_account.sip_accountable.image_url(:profile)
      else
        if self.sip_account.sip_accountable.male?
          '/assets/icons/user-male-16x.png'
        else
          '/assets/icons/user-female-16x.png'
        end
      end
    else
      nil
    end
  end

  def callstate
    if self.sip_account.call_legs.where(callstate: 'ACTIVE').any? || self.sip_account.b_call_legs.where(b_callstate: 'ACTIVE').any?
      'ACTIVE'
    else
      if self.sip_account.call_legs.where(callstate: 'EARLY').any?
        'EARLY'
      else
        if self.sip_account.call_legs.where(callstate: 'RINGING').any?
          'RINGING'
        else
          nil
        end
      end
    end
  end
  
end
