require 'test_helper'

class CallthroughTest < ActiveSupport::TestCase
  def setup
    # Basic setup of a new system
    #
    germany = Country.create(:name => "Germany", :country_code => "49",  :international_call_prefix => "00", :trunk_prefix => "0" )
    Language.create(:name => 'Deutsch', :code => 'de')
    AreaCode.create(:country => germany, :name => "Bendorf", :area_code => "2622")

    @gemeinschaft_setup = GemeinschaftSetup.new
    @gemeinschaft_setup.country  = Country.first
    @gemeinschaft_setup.language = Language.first

    @current_user = @gemeinschaft_setup.build_user(
                                            :user_name => I18n.t('gemeinschaft_setups.initial_setup.admin_name'), 
                                            :male => true,
                                            :email => 'admin@localhost',
                                            :first_name => 'Max',
                                            :last_name => 'Mustermann',
                                            :password => 'xxxxxxxxxx',
                                            :password_confirmation => 'xxxxxxxxxx',
                                            :language_id => Language.first.id,
                                          )
    @sip_domain = @gemeinschaft_setup.build_sip_domain(
      :host  => '10.0.0.1',
      :realm => '10.0.0.1',
    )

    @gemeinschaft_setup.save

    super_tenant = Tenant.create(
                                :name => SUPER_TENANT_NAME,
                                :country_id  => @gemeinschaft_setup.country.id, 
                                :language_id => @gemeinschaft_setup.language_id,
                                :description => I18n.t('gemeinschaft_setups.initial_setup.super_tenant_description'),
                                )

    # Admin
    super_tenant.tenant_memberships.create(:user_id => @gemeinschaft_setup.user.id)

    # Create the Super-Tenant's group:
    super_tenant_super_admin_group = super_tenant.user_groups.create(:name => I18n.t('gemeinschaft_setups.initial_setup.super_admin_group_name'))
    super_tenant_super_admin_group.user_group_memberships.create(:user_id => @gemeinschaft_setup.user.id)

    # Create the tenant.
    #
    @tenant = @sip_domain.tenants.build(:name => 'AMOOMA GmbH')
    @tenant.country  = Country.first
    @tenant.language = Language.first
    @tenant.internal_extension_ranges = '10-20'
    @tenant.did_list = '02622-70648-x, 02622-706480'
    @tenant.save

  @tenant.tenant_memberships.create(:user_id => @current_user.id)
  @current_user.update_attributes!(:current_tenant_id => @tenant.id)

  # The first user becomes a member of the 'admin' UserGroup
  #
  admin_group = @tenant.user_groups.create(:name => I18n.t('gemeinschaft_setups.initial_setup.admin_group_name'))
  admin_group.users << @current_user

  # User group
  #
  user_group = @tenant.user_groups.create(:name => I18n.t('gemeinschaft_setups.initial_setup.user_group_name'))
  user_group.users << @current_user

  # Generate the internal_extensions
  #
  @tenant.generate_internal_extensions

  # Generate the external numbers (DIDs)
  #
  @tenant.generate_dids
  end

  test 'the setup should create a valid system' do
    # Basics
    #
    assert_equal 1, Country.count
    assert_equal 1, Language.count

    # Testing the installation
    #
    assert @gemeinschaft_setup.valid?
    assert @sip_domain.valid?
    assert @current_user.valid?

    assert @tenant.valid?

    assert_equal 0, SipAccount.count
    assert_equal 2, Tenant.count
    assert_equal 1, User.count

    # Check the amount of phone_numbers
    #
    assert_equal 11, @tenant.phone_number_ranges.find_by_name(INTERNAL_EXTENSIONS).phone_numbers.count
    assert_equal 12, @tenant.phone_number_ranges.find_by_name(DIRECT_INWARD_DIALING_NUMBERS).phone_numbers.count
  end

  test 'that a callthrough can only be created with at least one DID' do
    assert_equal 0, Callthrough.count
 
    did = @tenant.phone_number_ranges.find_by_name(DIRECT_INWARD_DIALING_NUMBERS).phone_numbers.first

    callthrough = @tenant.callthroughs.build

    assert !callthrough.valid?

    callthrough.phone_numbers.build(:number => did.number)

    assert callthrough.save
    assert_equal 1, Callthrough.count
  end

  # TODO Activate this after fixing unique phone_number
  #
  # test 'that one DID can not be used by two different callthroughs' do
  #   assert_equal 0, Callthrough.count
 
  #   did = @tenant.phone_number_ranges.find_by_name(DIRECT_INWARD_DIALING_NUMBERS).phone_numbers.first

  #   callthroughs = Array.new
  #   (1..2).each do |i|
  #     callthroughs[i] = @tenant.callthroughs.build
  #     callthroughs[i].phone_numbers.build(:number => did.number)
  #     callthroughs[i].save
  #   end

  #   assert callthroughs[1].valid?, '1st Callthrough is not valid'
  #   assert !callthroughs[2].valid?, '2nd Callthrough is not valid'
  # end

end
