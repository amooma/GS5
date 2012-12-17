class Callthrough < ActiveRecord::Base
  attr_accessible :name, :clip_no_screening,
                  :phone_numbers_attributes, :access_authorizations_attributes,
                  :whitelists_attributes

  # Validations and Associations
  #
  belongs_to :tenant

  validates_presence_of :tenant_id
  validates_presence_of :tenant

  # These are the phone_numbers for this callthrough.
  # One has to dial this number to access the callthrough.
  #
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy

  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  validate :requires_at_least_one_phone_number

  # These are the access authorizations for this callthrough.
  # One has to be known by his phone number or by a login/pin or even both.
  #
  has_many :access_authorizations, :as => :access_authorizationable, :dependent => :destroy

  accepts_nested_attributes_for :access_authorizations, 
                                :reject_if => lambda { |access_authorization| access_authorization[:login].blank? && access_authorization[:pin].blank? && access_authorization[:phone_numbers_attributes]['0'][:number].blank? },
                                :allow_destroy => true

  has_many :access_authorization_phone_numbers, :source => :phone_numbers, 
           :through => :access_authorizations, :readonly => true

  # These are the whitelists of the phone numbers which can be called through this callthrough.
  #
  has_many :whitelists, :as => :whitelistable, :dependent => :destroy

  accepts_nested_attributes_for :whitelists, 
                                :reject_if => lambda { |whitelist| whitelist[:phone_numbers_attributes]['0']['number'].blank? }, 
                                :allow_destroy => true

  has_many :whitelisted_phone_numbers, :source => :phone_numbers, 
           :through => :whitelists, :readonly => true

  # Delegations:
  #
  delegate :sip_domain, :to => :tenant, :allow_nil => true

  def to_s
    self.name || I18n.t('callthroughs.name') + ' ID ' + self.id
  end


  private
  def requires_at_least_one_phone_number
    errors.add(:base, "You must provide at least one phone number") if !self.phone_numbers.map{|phone_number| phone_number.valid?}.include?(true)
  end
end
