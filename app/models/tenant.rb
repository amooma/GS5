# encoding: UTF-8

class Tenant < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  # Associations:
  #
  has_many :tenant_memberships, :dependent => :destroy
  has_many :users, :through => :tenant_memberships, :validate => true
  
  has_many :user_groups, :dependent => :destroy
  
  has_many :phone_books, :as => :phone_bookable, :dependent => :destroy
  has_many :phone_book_entries, :through => :phone_books

  has_many :phone_number_ranges, :as => :phone_number_rangeable, :dependent => :destroy
 
  has_many :phones, :as => :phoneable, :dependent => :destroy
  has_many :users_phones, :through => :users, :source => :phones, :readonly => true

  has_many :callthroughs, :dependent => :destroy

  has_many :fax_accounts, :dependent => :destroy # A tenant can't have a FaxAccount by itself!
  
  belongs_to :country
  belongs_to :language
  
  belongs_to :sip_domain
  
  has_many :sip_accounts, :as => :sip_accountable, :dependent => :destroy
  has_many :users_sip_accounts, :through => :users, :source => :sip_accounts, :readonly => true
  
  has_many :conferences, :as => :conferenceable, :dependent => :destroy

  has_many :hunt_groups, :dependent => :destroy
  has_many :hunt_group_members, :through => :hunt_groups

  has_many :automatic_call_distributors, :as => :automatic_call_distributorable, :dependent => :destroy
  has_many :acd_agents, :through => :automatic_call_distributors

  has_many :parking_stalls, :as => :parking_stallable, :dependent => :destroy

  # Phone numbers of the tenant.
  #
  has_many :phone_number_ranges_phone_numbers, :through => :phone_number_ranges, :source => :phone_numbers, :readonly => true
  has_many :phone_numbers, :through => :sip_accounts
  has_many :conferences_phone_numbers, :through => :conferences, :source => :phone_numbers, :readonly => true
  has_many :callthroughs_phone_numbers, :through => :conferences, :source => :phone_numbers, :readonly => true
  has_many :huntgroups_phone_numbers, :through => :conferences, :source => :phone_numbers, :readonly => true
  has_many :fax_accounts_phone_numbers, :through => :fax_accounts, :source => :phone_numbers, :readonly => true
  
  # Phone numbers of users of the tenant.
  #
  has_many :users_phone_numbers, :through => :users, :source => :phone_numbers, :readonly => true
  has_many :user_groups_phone_numbers, :through => :users, :source => :phone_numbers, :readonly => true
  has_many :users_conferences, :through => :users, :source => :conferences, :readonly => true
  has_many :users_conferences_phone_numbers, :through => :users_conferences, :source => :phone_numbers, :readonly => true
  has_many :users_fax_accounts, :through => :users, :source => :fax_accounts, :readonly => true
  has_many :users_fax_accounts_phone_numbers, :through => :users_fax_accounts, :source => :phone_numbers, :readonly => true

  # Groups
  has_many :group_memberships, :as => :item, :dependent => :destroy, :uniq => true
  has_many :groups, :through => :group_memberships

  has_many :voicemail_accounts, :as => :voicemail_accountable, :dependent => :destroy

  # Validations:
  #
  validates_presence_of :name, :state, :country, :language
  validates_length_of :name, :within => 1..255
  validates_uniqueness_of :name
  
  validates_length_of :name, :within => 1..100

  # Before and after hooks:
  # 
  after_create :create_a_default_phone_book

  # State machine:
  default_scope where(:state => 'active')
  state_machine :initial => :active do
    
    event :deactivate do
      transition [:active] => :deactivated
    end
    
    event :activate do
      transition [:deactivated] => :active
    end
  end
  
  def to_s
    name
  end
  
  if GsParameter.get('STRICT_INTERNAL_EXTENSION_HANDLING') == true
    def array_of_internal_extension_numbers
      ranges = self.internal_extension_ranges.gsub(/[^0-9\-,]/,'').gsub(/[\-]+/,'-').gsub(/[,]+/,',').split(/,/)
      output = []
      ranges.each do |range|
        mini_range = range.split(/-/).map{|x| x.to_i}.sort
        if mini_range.size == 1
          output << mini_range[0]
        else
          output = output + (mini_range[0]..mini_range[1]).to_a
        end
        output = output.try(:flatten)
      end    
      output.try(:sort).try(:uniq).map{|number| number.to_s }
    end

    # Generate the internal_extensions
    #
    def generate_internal_extensions
      internal_extensions = self.phone_number_ranges.find_or_create_by_name(GsParameter.get('INTERNAL_EXTENSIONS'), :description => 'A list of all available internal extensions.')
      
      phone_number_list = Array.new

      if self.array_of_internal_extension_numbers.size > 0
        if self.country.phone_number_ranges.first.try(:phone_numbers) == nil
          phone_number_list = self.array_of_internal_extension_numbers
        elsif 
          # Don't create extensions like 911, 110 or 112 (at least by default)
          #
          phone_number_list = (self.array_of_internal_extension_numbers - self.country.phone_number_ranges.where(:name => GsParameter.get('SERVICE_NUMBERS')).first.phone_numbers.map{|entry| entry.number})
        end
      end

      phone_number_list.each do |number|
        internal_extensions.phone_numbers.find_or_create_by_name_and_number('Extension', number)
      end
    end
      
  end

  if GsParameter.get('STRICT_DID_HANDLING') == true
    def array_of_dids_generated_from_did_list
      numbers = self.did_list.downcase.gsub(/[^0-9,x\+]/,'').gsub(/[,]+/,',').split(/,/)
      array_of_all_external_numbers = []
      numbers.each do |number|
        if number.include?('x')
          self.array_of_internal_extension_numbers.each do |internal_extension|
            array_of_all_external_numbers << number.gsub(/x/, "-#{internal_extension.to_s}")
          end
        else
          array_of_all_external_numbers << number
        end
      end
      array_of_all_external_numbers.try(:sort).try(:uniq).map{|number| number.to_s }
    end

    # Generate the external numbers (DIDs)
    #
    def generate_dids
      dids = self.phone_number_ranges.find_or_create_by_name(GsParameter.get('DIRECT_INWARD_DIALING_NUMBERS'), :description => 'A list of all available DIDs.')
      self.array_of_dids_generated_from_did_list.each do |number|
        dids.phone_numbers.find_or_create_by_name_and_number('DID', number)
      end
    end
    
  end  
  
  
  # All phone_numbers which can be used
  #
  def internal_extensions_and_dids
    @internal_extensions_and_dids ||= self.phone_number_ranges_phone_numbers.
         where(:phone_numberable_type => 'PhoneNumberRange').
         where(:phone_numberable_id => self.phone_number_ranges.
         where(:name => [GsParameter.get('INTERNAL_EXTENSIONS'), GsParameter.get('DIRECT_INWARD_DIALING_NUMBERS')]).
         map{|pnr| pnr.id })
  end

  def array_of_internal_extensions
    @array_of_internal_extensions ||= self.phone_number_ranges_phone_numbers.
         where(:phone_numberable_type => 'PhoneNumberRange').
         where(:phone_numberable_id => self.phone_number_ranges.
         where(:name => GsParameter.get('INTERNAL_EXTENSIONS')).
         map{|pnr| pnr.id }).
         map{|phone_number| phone_number.number }.
         sort.uniq
  end

  def array_of_dids
    @array_of_dids ||= self.phone_number_ranges_phone_numbers.
         where(:phone_numberable_type => 'PhoneNumberRange').
         where(:phone_numberable_id => self.phone_number_ranges.where(:name => GsParameter.get('DIRECT_INWARD_DIALING_NUMBERS')).map{|pnr| pnr.id }).
         map{|phone_number| phone_number.to_s }.
         sort.uniq
  end

  def array_of_assigned_phone_numbers
    (self.phone_numbers + self.conferences_phone_numbers + 
    self.callthroughs_phone_numbers + self.huntgroups_phone_numbers + 
    self.fax_accounts_phone_numbers + self.users_phone_numbers + 
    self.user_groups_phone_numbers + self.users_conferences_phone_numbers +  
    self.users_fax_accounts_phone_numbers).
    map{|phone_number| phone_number.number }.
    sort.uniq
  end

  def array_of_available_internal_extensions
    (self.array_of_internal_extensions - self.array_of_assigned_phone_numbers).sort.uniq
  end  

  def array_of_available_dids
    (self.array_of_dids - self.array_of_assigned_phone_numbers).sort.uniq
  end

  def array_of_available_internal_extensions_and_dids
    self.array_of_available_internal_extensions + self.array_of_available_dids
  end

  private
  
  # Create a public phone book for this tenant
  def create_a_default_phone_book
    if self.name != GsParameter.get('SUPER_TENANT_NAME')
      general_phone_book = self.phone_books.find_or_create_by_name_and_description(
        I18n.t('phone_books.general_phone_book.name'),
        I18n.t('phone_books.general_phone_book.description', :resource => self.to_s)
        )
      amooma = general_phone_book.phone_book_entries.create(
        :organization => 'AMOOMA GmbH',
        :is_organization => true,
        :description => "Hersteller von Gemeinschaft. Kommerziellen Support und Consulting für Gemeinschaft.",
        :homepage_organization => 'http://amooma.de',
        :twitter_account => 'amooma_de',
        :facebook_account => 'AMOOMA.GmbH',
      )
      amooma.phone_numbers.create(
        :name => 'Office', 
        :number => '+492622983440'
      )
      amooma.addresses.create(
        :street => 'Bachstr. 124', 
        :zip_code => '56566',
        :city => 'Neuwied',
        :country_id => Country.where(:country_code => 49).first.try(:id),
      )
    end
  end
end
