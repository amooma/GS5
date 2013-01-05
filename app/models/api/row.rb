class Api::Row < ActiveRecord::Base

  # This is the place to do some basic mapping.
  #
  alias_attribute :UserName, :user_name
  alias_attribute :LastName, :last_name
  alias_attribute :FirstName, :first_name
  alias_attribute :PhoneOffice, :office_phone_number
  alias_attribute :VoipNr, :internal_extension
  alias_attribute :CellPhone, :mobile_phone_number
  alias_attribute :Fax, :fax_phone_number
  alias_attribute :Email, :email
  alias_attribute :PIN, :pin
  alias_attribute :PIN_LastUpdate, :pin_updated_at
  alias_attribute :Photo, :photo_file_name

  belongs_to :user

  # Validations
  #
  validates_presence_of :user_name
  validates_uniqueness_of :user_name

  after_destroy :destroy_user

  def to_s
    self.user_name
  end

  def create_a_new_gemeinschaft_user
    tenant = Tenant.find(GsParameter.get('DEFAULT_API_TENANT_ID'))

    # Find or create the user
    #
    if tenant.users.where(:user_name => self.user_name).count > 0
      user = tenant.users.where(:user_name => self.user_name).first
    else
      user = tenant.users.create(
                                :user_name => self.user_name,
                                :last_name => self.last_name,
                                :first_name => self.first_name,
                                :middle_name => self.middle_name,
                                :email => self.email,
                                :new_pin => self.pin,
                                :new_pin_confirmation => self.pin,
                                :password => self.pin,
                                :password_confirmation => self.pin,
                                :language_id => tenant.language_id,
                              )
    end

    self.update_attributes({:user_id => user.id})

    # Find or create a sip_account
    #
    if user.sip_accounts.count > 0
      sip_account = user.sip_accounts.first
    else
      sip_account = user.sip_accounts.create(
                                            :caller_name => self.user.to_s,
                                            :voicemail_pin => self.pin,
                                            )
    end

    # Create phone_numbers to this sip_account (BTW: phone_numbers are unqiue)
    #
    sip_account.phone_numbers.create(:number => self.internal_extension)
    sip_account.phone_numbers.create(:number => self.office_phone_number)


    # Find or create a fax account
    #
    if user.fax_accounts.count > 0
      fax_account = user.fax_accounts.first
    else
      fax_account = user.fax_accounts.create(
                                              :name => 'Default Fax',
                                              :station_id => user.to_s,
                                              :email => self.email,
                                              :days_till_auto_delete => 90,
                                              :retries => 3,
                                            )
    end

    # Create phone_numbers to this fax_account
    #
    fax_account.phone_numbers.create(:number => self.fax_phone_number)

  end

  def destroy_user
    self.user.destroy
  end

  def update_user_data
    user = self.user
    user.update_attributes(
                          :user_name => self.user_name,
                          :last_name => self.last_name,
                          :first_name => self.first_name,
                          :middle_name => self.middle_name,
                          :email => self.email,
                          :new_pin => self.pin,
                          :new_pin_confirmation => self.pin,
                          :password => self.pin,
                          :password_confirmation => self.pin,
                          )

    # Find or create a sip_account
    #
    if user.sip_accounts.count > 0
      sip_account = user.sip_accounts.first
    else
      sip_account = user.sip_accounts.create(
                                            :caller_name => self.user.to_s,
                                            :voicemail_pin => self.pin,
                                            )
    end

    # Delete old phone_numbers
    #
    sip_account.phone_numbers.destroy_all

    # Create phone_numbers to this sip_account (BTW: phone_numbers are unqiue)
    #
    sip_account.phone_numbers.create(:number => self.internal_extension)
    sip_account.phone_numbers.create(:number => self.office_phone_number)

    # Find or create a fax account
    #
    if user.fax_accounts.count > 0
      fax_account = user.fax_accounts.first
    else
      fax_account = user.fax_accounts.create(
                                              :name => 'Default Fax',
                                              :station_id => user.to_s,
                                              :email => self.email,
                                              :days_till_auto_delete => 90,
                                              :retries => 3,
                                            )
    end

    # Delete old phone_number
    #
    fax_account.phone_numbers.destroy_all

    # Create phone_numbers to this fax_account
    #
    fax_account.phone_numbers.create(:number => self.fax_phone_number)
  end

end
