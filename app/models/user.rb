require 'digest/sha2'

class User < ActiveRecord::Base
  after_create :create_a_default_phone_book, :if => :'is_native != false'

  # Sync other nodes when this is a cluster.
  #
  after_create :create_on_other_gs_nodes
  after_create :create_default_group_memberships
  after_destroy :destroy_on_other_gs_nodes
  after_update :update_on_other_gs_nodes
  
  attr_accessible :user_name, :email, :password, :password_confirmation, 
                  :first_name, :middle_name, :last_name, :male,
                  :image, :current_tenant_id, :language_id,
                  :new_pin, :new_pin_confirmation, :send_voicemail_as_email_attachment,
                  :importer_checksum, :gs_node_id
  
  attr_accessor :new_pin, :new_pin_confirmation
  
  before_validation {
    # If the PIN and PIN confirmation are left blank in the GUI
    # then the user/admin does not want to change the PIN.
    if self.new_pin.blank? && self.new_pin_confirmation.blank?
      self.new_pin              = nil
      self.new_pin_confirmation = nil
    end
  }
  
  validates_length_of [:new_pin, :new_pin_confirmation],
    :minimum => (GsParameter.get('MINIMUM_PIN_LENGTH').nil? ? 4 : GsParameter.get('MINIMUM_PIN_LENGTH')), 
    :maximum => (GsParameter.get('MAXIMUM_PIN_LENGTH').nil? ? 10 : GsParameter.get('MAXIMUM_PIN_LENGTH')),
    :allow_blank => true, :allow_nil => true
  validates_format_of [:new_pin, :new_pin_confirmation],
    :with => /^[0-9]+$/,
    :allow_blank => true, :allow_nil => true,
    :message => "must be numeric."
  
  validates_confirmation_of :new_pin, :if => :'pin_changed?'
  before_save :hash_new_pin, :if => :'pin_changed?'
  
  has_secure_password
  
  validates_presence_of :password, :password_confirmation, :on => :create, :if => :'password_digest.blank?'
  validates_presence_of :email
  validates_presence_of :last_name
  validates_presence_of :first_name
  validates_presence_of :user_name
  
  validates_uniqueness_of :user_name, :case_sensitive => false
  validates_uniqueness_of :email, :allow_nil => true, :case_sensitive => false
  
  validates_length_of :user_name, :within => 0..50

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  # Associations:
  #
  has_many :tenant_memberships, :dependent => :destroy
  has_many :tenants, :through => :tenant_memberships
  
  has_many :user_group_memberships, :dependent => :destroy, :uniq => true
  has_many :user_groups, :through => :user_group_memberships
  
  has_many :phone_books, :as => :phone_bookable, :dependent => :destroy
  has_many :phone_book_entries, :through => :phone_books
  
  has_many :phones, :as => :phoneable
  has_many :sip_accounts, :as => :sip_accountable, :dependent => :destroy
  has_many :phone_numbers, :through => :sip_accounts
  
  has_many :conferences, :as => :conferenceable, :dependent => :destroy
  
  has_many :fax_accounts, :as => :fax_accountable, :dependent => :destroy

  has_many :auto_destroy_access_authorization_phone_numbers, :class_name => 'PhoneNumber', :foreign_key => 'access_authorization_user_id', :dependent => :destroy
  
  belongs_to :current_tenant, :class_name => 'Tenant'
  validates_presence_of :current_tenant, :if => Proc.new{ |user| user.current_tenant_id }

  belongs_to :language
  validates_presence_of :language_id
  validates_presence_of :language
  
  validate :current_tenant_is_included_in_tenants, :if => Proc.new{ |user| user.current_tenant_id }

  belongs_to :gs_node

  has_many :parking_stalls, :as => :parking_stallable, :dependent => :destroy

  has_many :group_memberships, :as => :item, :dependent => :destroy, :uniq => true
  has_many :groups, :through => :group_memberships
  
  has_many :switchboards, :dependent => :destroy

  has_many :voicemail_accounts, :as => :voicemail_accountable, :dependent => :destroy

  has_many :generic_files, :as => :owner, :dependent => :destroy

  # Avatar like photo  
  mount_uploader :image, ImageUploader  

  before_save :format_email_and_user_name

  before_destroy :destroy_or_logout_phones

  after_save :become_a_member_of_default_user_groups

  def destroy
    clean_whitelist_entries
    super
  end

  def pin_changed?
    ! @new_pin.blank?
  end
  
  def sip_domain
    if self.current_tenant
      return self.current_tenant.sip_domain
    end
    return nil
  end
  
  def to_s
    max_first_name_length = 10
    max_last_name_length = 20
    if self.first_name.blank?
      self.last_name.strip
    else  
      "#{self.first_name.strip} #{self.last_name.strip}"
    end
  end
  
  def self.find_user_by_phone_number( number, tenant )
    tenant = Tenant.where( :id => tenant.id ).first
    if tenant
      if tenant.sip_domain
        user = tenant.sip_domain.sip_accounts.
          joins(:phone_numbers).
          where(:phone_numbers => { :number => number }).
          first.
          try(:sip_accountable)
        if user.class.name == 'User'
          return user
        end
      end
    end
    return nil
  end
  
  def authenticate_by_pin?( entered_pin )
    self.pin_hash == Digest::SHA2.hexdigest( "#{self.pin_salt}#{entered_pin}" )
  end
  
  def admin?
    self.user_groups.include?(UserGroup.find(2))
  end

  def sim_cards
    SimCard.where(:sip_account_id => self.sip_account_ids)
  end

  private
  
  def hash_new_pin
    if @new_pin \
    && @new_pin_confirmation \
    && @new_pin_confirmation == @new_pin
      self.pin_salt = SecureRandom.base64(8)
      self.pin_hash = Digest::SHA2.hexdigest(self.pin_salt + @new_pin)
    end
  end
  
  def format_email_and_user_name
    self.email = self.email.downcase.strip if !self.email.blank?
    self.user_name = self.user_name.downcase.strip if !self.user_name.blank?
  end
  
  # Create a personal phone book for this user:
  def create_a_default_phone_book
    private_phone_book = self.phone_books.find_or_create_by_name_and_description(
      I18n.t('phone_books.private_phone_book.name', :resource => self.to_s),
      I18n.t('phone_books.private_phone_book.description')
    )
  end
  
  # Check if a current_tenant_id is possible tenant_membership wise.
  def current_tenant_is_included_in_tenants
    if !self.tenants.include?(Tenant.find(self.current_tenant_id))
      errors.add(:current_tenant_id, "is not possible (no TenantMembership)")
    end
  end

  # Make sure that there are no whitelist entries with phone_numbers of 
  # a just destroyed user.
  #
  def clean_whitelist_entries
    phone_numbers = PhoneNumber.where( :phone_numberable_type => 'Whitelist').
                                where( :number => self.phone_numbers.map{ |x| x.number } )
    phone_numbers.each do |phone_number|
      if phone_number.phone_numberable.whitelistable.class == Callthrough
        whitelist = Whitelist.find(phone_number.phone_numberable)
        phone_number.destroy
        if whitelist.phone_numbers.count == 0
          # Very lickly that this Whitelist doesn't make sense any more.
          #
          whitelist.destroy
        end
      end
    end
  end

  # Make sure that a tenant phone goes back to the tenant and doesn't
  # get deleted with this user.
  #
  def destroy_or_logout_phones
    self.phones.each do |phone|
      if phone.sip_accounts.where(:sip_accountable_type => 'Tenant').count > 0
        phone.user_logout
      else
        phone.destroy
      end
      phone.resync
    end
  end

  # Normaly a new user should become a member of default user groups.
  #
  def become_a_member_of_default_user_groups
    UserGroup.where(:id => GsParameter.get('DEFAULT_USER_GROUPS_IDS')).each do |user_group|
      user_group.user_group_memberships.create(:user_id => self.id)
    end
  end

  def create_default_group_memberships
    templates = GsParameter.get('User', 'group', 'default')
    if templates.class == Array
      templates.each do |group_name|
        group = Group.where(:name => group_name).first
        if group
          self.group_memberships.create(:group_id => group.id)
        end
      end
    end
  end

end
