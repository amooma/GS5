class PhoneNumber < ActiveRecord::Base
  NUMBER_TYPES_INBOUND = ['SipAccount', 'Conference', 'FaxAccount', 'Callthrough', 'HuntGroup']  

  attr_accessible :name, :number, :gs_node_id, :access_authorization_user_id

  has_many :call_forwards, :as => :call_forwardable, :dependent => :destroy
  
  has_many :ringtones, :as => :ringtoneable, :dependent => :destroy
  
  belongs_to :phone_numberable, :polymorphic => true

  belongs_to :gs_node

  validates_uniqueness_of :number, :scope => [:phone_numberable_type, :phone_numberable_id]
  
  validate :validate_inbound_uniqueness
    
  before_save :save_value_of_to_s
  after_create :copy_existing_call_forwards_if_necessary
  before_validation :'parse_and_split_number!'
  validate :validate_number, :if => Proc.new { |phone_number| GsParameter.get('STRICT_INTERNAL_EXTENSION_HANDLING') && GsParameter.get('STRICT_DID_HANDLING') }
  validate :check_if_number_is_available, :if => Proc.new { |phone_number| GsParameter.get('STRICT_INTERNAL_EXTENSION_HANDLING') && GsParameter.get('STRICT_DID_HANDLING') }
  
  acts_as_list :scope => [:phone_numberable_id, :phone_numberable_type]

  # Sync other nodes when this is a cluster.
  #
  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  after_create { self.create_on_other_gs_nodes('phone_numberable', self.phone_numberable.try(:uuid)) }
  after_destroy :destroy_on_other_gs_nodes
  after_update { self.update_on_other_gs_nodes('phone_numberable', self.phone_numberable.try(:uuid)) }  

  # State machine:
  #
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
  	parts = []
  	parts << "+#{self.country_code}" if self.country_code
  	parts << self.area_code if self.area_code
  	parts << self.central_office_code if self.central_office_code
  	parts << self.subscriber_number if self.subscriber_number

  	if parts.empty?
  		return self.number
  	end
  	return parts.join("-")
  end
  
  # Parse a number in a tenant's context (respect the tenant's country)
  #
  def self.parse( number, tenant=nil )
    number = number.to_s.gsub( /[^0-9+]/, '' )
  
    if tenant.class.name == 'Tenant'
      country = tenant.country
    else
      tenant = nil
      country = GemeinschaftSetup.first.try(:country)
      country ||= Country.where(:name => "Germany").first
    end
  
    parts = {
      :country_code         => nil,
      :area_code            => nil,
      :central_office_code  => nil,
      :subscriber_number    => nil,
      :extension            => nil,
    }
  
    if country
      if ! country.international_call_prefix.blank?
        number = number.gsub( /^#{Regexp.escape( country.international_call_prefix )}/, '+' )
      end
      if ! country.trunk_prefix.blank?
        number = number.gsub( /^#{Regexp.escape( country.trunk_prefix )}/, "+#{country.country_code}" )
      end
    end
  
    if number.match( /^[+]/ )
      parts = self.parse_international_number( number.gsub(/[^0-9]/,'') )
      return nil if parts.nil?
    else
      # Check if the number is an internal extension.
      if tenant
        internal_extension_range = tenant.phone_number_ranges.where(:name => GsParameter.get('INTERNAL_EXTENSIONS')).first
        if internal_extension_range
          if internal_extension_range.phone_numbers.where(:number => number).length > 0
            parts[:extension] = number
          end
        end
      end
    
      # Otherwise assume the number is a special number such as an emergency number.
      if ! parts[:extension]
        parts[:subscriber_number] = number
      end
    end
  
    # return nil if all parts are blank:
    return nil if (
      parts[:country_code].blank? &&
      parts[:area_code].blank? &&
      parts[:central_office_code].blank? &&
      parts[:subscriber_number].blank? &&
      parts[:extension].blank?
    )
    parts  # return value
  end

  def self.parse_and_format( number, tenant=nil )
    attributes = PhoneNumber.parse(number, tenant)
    if attributes
      formated_number = attributes.map{|key,value| value}.delete_if{|x| x.nil?}.join('-')
      formated_number = "+#{formated_number}" if attributes[:country_code]
      return formated_number
    end
    return number
  end
  
  # Parse an international number.
  # Assumed format for +number+ is e.g. "49261200000"
  #
  def self.parse_international_number( number )
    number = number.to_s.gsub( /[^0-9]/, '' )
    
    parts = {
      :country_code         => nil,
      :area_code            => nil,
      :central_office_code  => nil,
      :subscriber_number    => nil,
      :extension            => nil,
    }
    
    # Find country by country code:
    country   = Country.where( :country_code => number[0, 3]).first
  	country ||= Country.where( :country_code => number[0, 2]).first
    country ||= Country.where( :country_code => number[0, 1]).first
    
    return nil if ! country  # invalid number format
    
    parts[:country_code] = country.country_code
    remainder = number[ parts[:country_code].length, 999 ]  # e.g. "261200000"
    
    case parts[:country_code]
      
      when '1'
        # Assure an NANP number
        return nil if ! remainder.match(/[2-9]{1}[0-9]{2}[2-9]{1}[0-9]{2}[0-9]{4}/)

        # Shortcut for NANPA closed dialplan:
        parts[:area_code           ] = remainder[ 0,  3]
        parts[:central_office_code ] = remainder[ 3,  3]
        parts[:subscriber_number   ] = remainder[ 6,  4]      
      else
        # variable-length dialplan, e.g. Germany
        
        # Find longest area_code for the country:
        longest_area_code = country.area_codes.order( "LENGTH(area_code) DESC" ).first
        
        # Find a matching area_code:
        if longest_area_code
          longest_area_code.area_code.length.downto(1) do |area_code_length|
            area_code = country.area_codes.where( :area_code => remainder[ 0, area_code_length ] ).first
            if area_code
              parts[:area_code] = area_code.area_code
              break
            end
          end
          
          return nil if ! parts[:area_code] # No matching area_code for the country.
          
          remainder = remainder.gsub( /^#{parts[:area_code]}/, '' )
          #remainder = number[ parts[:area_code].length, 999 ]  # e.g. "200000"
        end
        parts[:subscriber_number] = remainder
    end
    
    parts  # return value
  end
  
  def parse_and_split_number!
    if self.phone_numberable_type == 'PhoneNumberRange' && self.phone_numberable.name == GsParameter.get('INTERNAL_EXTENSIONS')
      # The parent is the PhoneNumberRange GsParameter.get('INTERNAL_EXTENSIONS'). Therefor it must be an extensions.
      #
      self.country_code = nil
      self.area_code = nil
      self.subscriber_number = nil
      self.central_office_code = nil
      self.extension = self.number.to_s.strip
    else
      if self.tenant &&
         self.tenant.phone_number_ranges.exists?(:name => GsParameter.get('INTERNAL_EXTENSIONS')) && 
         self.tenant.phone_number_ranges.where(:name => GsParameter.get('INTERNAL_EXTENSIONS')).first.phone_numbers.exists?(:number => self.number)
        self.country_code = nil
        self.area_code = nil
        self.subscriber_number = nil
        self.central_office_code = nil
        self.extension = self.number.to_s.strip         
      else
        prerouting = resolve_prerouting
        if prerouting && !prerouting['destination_number'].blank? && prerouting['type'] == 'phonenumber'
          self.number = prerouting['destination_number']
        end 
        parsed_number = PhoneNumber.parse( self.number )
        if parsed_number
          self.country_code = parsed_number[:country_code]
          self.area_code = parsed_number[:area_code]
          self.subscriber_number = parsed_number[:subscriber_number]
          self.extension = parsed_number[:extension]
          self.central_office_code = parsed_number[:central_office_code]
      
          self.number = self.to_s.gsub( /[^\+0-9]/, '' )
        end
      end
    end
  end

  def resolve_prerouting
    return PhoneNumber.resolve_prerouting(self.number.strip, self.phone_numberable)
  end

  def self.resolve_prerouting(number, account = nil)
    account = account || SipAccount.first

    routes = CallRoute.test_route(:prerouting, {
      'caller.destination_number' => number,
      'caller.auth_account_type' => account.class.name, 
      'caller.auth_account_id' => account.id, 
      'caller.auth_account_uuid' => account.try(:uuid),
      'caller.account_type' => account.class.name, 
      'caller.account_id' => account.id, 
      'caller.account_uuid' => account.try(:uuid),
    })

    if routes
      return routes['routes']['1']
    end
  end
  
  # Find the (grand-)parent tenant of this phone number:
  #
  def tenant
    #OPTIMIZE Add a tenant_id to SipAccount
    case self.phone_numberable
      when SipAccount
        self.phone_numberable.tenant
      when Conference
        case self.phone_numberable.conferenceable
          when Tenant
            self.phone_numberable.conferenceable
          when User
            self.phone_numberable.conferenceable.current_tenant  #OPTIMIZE
          when UserGroup
            self.phone_numberable.conferenceable.tenant
        end
    end
  end
  
  def move_up?
    return self.position.to_i > PhoneNumber.where(:phone_numberable_id => self.phone_numberable_id, :phone_numberable_type => self.phone_numberable_type ).order(:position).first.position.to_i
  end

  def move_down?
    return self.position.to_i < PhoneNumber.where(:phone_numberable_id => self.phone_numberable_id, :phone_numberable_type => self.phone_numberable_type ).order(:position).last.position.to_i
  end

  private
  
  def validate_number
    if ! PhoneNumber.parse( self.number )
      errors.add( :number, "is invalid." )
    end
  end
  
  def check_if_number_is_available
    if self.phone_numberable_type != 'PhoneBookEntry' && self.tenant

      phone_number_ranges = self.tenant.phone_number_ranges.where(
                              :name => [GsParameter.get('INTERNAL_EXTENSIONS'), GsParameter.get('DIRECT_INWARD_DIALING_NUMBERS')]
                            )
      if !phone_number_ranges.empty?                           
        if !PhoneNumber.where(:phone_numberable_type => 'PhoneNumberRange').
                        where(:phone_numberable_id => phone_number_ranges).
                        exists?(:number => self.number)                              
           errors.add(:number, "isn't defined as an extenation or DID for the tenant '#{self.tenant}'. #{phone_number_ranges.inspect}")
        end
      end
    end
  end

  def validate_inbound_uniqueness
    if NUMBER_TYPES_INBOUND.include?(self.phone_numberable_type)
      numbering_scope = PhoneNumber.where(:state => 'active', :number => self.number, :phone_numberable_type => NUMBER_TYPES_INBOUND)
      if numbering_scope.where(:id => self.id).count == 0 && numbering_scope.count > 0
        errors.add(:number, 'not unique')
      end
    end
  end
  
  def save_value_of_to_s
    self.value_of_to_s = self.to_s
  end
  
  def copy_existing_call_forwards_if_necessary
    if self.phone_numberable.class == SipAccount && self.phone_numberable.callforward_rules_act_per_sip_account == true
      sip_account = SipAccount.find(self.phone_numberable)
      if sip_account.phone_numbers.where('id != ?', self.id).count > 0
        if sip_account.phone_numbers.where('id != ?', self.id).order(:created_at).first.call_forwards.count > 0
          sip_account.phone_numbers.where('id != ?', self.id).first.call_forwards.each do |call_forward|
            call_forward.set_this_callforward_rule_to_all_phone_numbers_of_the_parent_sip_account
          end
        end
      end
    end
  end

end
