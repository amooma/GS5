class AccessAuthorization < ActiveRecord::Base
  attr_accessible :name, :login, :pin, :phone_numbers_attributes, :sip_account_id

  belongs_to :access_authorizationable, :polymorphic => true

  validates_uniqueness_of :name, :scope => [ :access_authorizationable_type, :access_authorizationable_id ],
                                 :allow_nil => true, :allow_blank => true

  # The login is optional. But if set has to be done with digits only.
  #
  validates_format_of :login, :with => /\A([0-9]+)\Z/, 
                      :allow_nil => true, :allow_blank => true,
                      :message => "must be numeric."

  # The PIN is optional. But when set it has to be a proper PIN.
  #
  validates_format_of :pin, :with => /\A([0-9]+)\Z/, 
                      :allow_nil => true, :allow_blank => true,
                      :message => "must be numeric."

  validates_length_of :pin, :minimum => MINIMUM_PIN_LENGTH, :maximum => MAXIMUM_PIN_LENGTH,
                      :allow_nil => true, :allow_blank => true

  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  # Optional SIP account.
  #
  belongs_to :sip_account

  validates_presence_of :sip_account, :if => Proc.new{ |access_authorization| !access_authorization.sip_account_id.blank? }, 
                        :message => 'Given SIP account does not exist.'

  acts_as_list :scope => [ :access_authorizationable_type, :access_authorizationable_id ]

  def to_s
    self.name || I18n.t('access_authorizations.name') + ' ID ' + self.id.to_s
  end
end
