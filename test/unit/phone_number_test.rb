# ruby coding: utf-8

require 'test_helper'

class PhoneNumberTest < ActiveSupport::TestCase
  
  test "should have valid factory" do
    assert FactoryGirl.build(:phone_number).valid?
  end
  
  def test_that_the_initial_state_should_be_active
    @phone_number = FactoryGirl.create(:phone_number)
    assert_equal 'active', @phone_number.state
    assert @phone_number.active?
  end
  
  test "that the value_of_to_s field is filled" do
    phone_number = FactoryGirl.create(:phone_number)
    assert_equal phone_number.value_of_to_s, phone_number.to_s
  end
  
  {
    '+492612000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '+49 261 2000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '+49-261-2000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '492612000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '49888888882000' => nil,  # unknown area code
    '552612000' => nil,  # unknown country code
    '15551234567' => {
      :country_code => "1",
      :area_code => "555",
      :central_office_code => "123",
      :subscriber_number => "4567",
      :extension => nil,
    },
    '2612000' => nil,   # not an international number
    '02612000' => nil,  # not an international number
    '00492612000' => nil,  # invalid format
    '2000' => nil,
    '' => nil,
    nil => nil,
    '++++' => nil,
    '###' => nil,
    'äöü' => nil,
    false => nil,
    true => nil,  # true.to_s == "true"  # invalid number
  }.each_pair do |number, expected|
    test "should parse number #{number.inspect} correctly" do
      # load some country codes:
      usa     = Country.create(:name => "United States of America", :country_code => "1",  :international_call_prefix => "011", :trunk_prefix => "1" )
      germany = Country.create(:name => "Germany", :country_code => "49",  :international_call_prefix => "00", :trunk_prefix => "0" )
      cuba    = Country.create(:name => "Cuba", :country_code => "53",  :international_call_prefix => "119", :trunk_prefix => "" )
      # load some area codes:
      AreaCode.create(:country => germany, :name => "Koblenz am Rhein", :area_code => "261")
      AreaCode.create(:country => germany, :name => "Neuwied", :area_code => "2631")
      AreaCode.create(:country => germany, :name => "Berlin", :area_code => "30")
      AreaCode.create(:country => germany, :name => "Hamburg", :area_code => "40")
      AreaCode.create(:country => germany, :name => "Hohenmocker", :area_code => "39993")
      
      assert_equal expected, PhoneNumber.parse_international_number( number )
    end
  end
  
  {
    '+492612000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '+49 261 2000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '+49-261-2000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '110' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => "110",
      :extension => nil,
    },
    '11833' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => "11833",
      :extension => nil,
    },
    '15551234567' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => "15551234567",
      :extension => nil,
    },
    '0015551234567' => {
      :country_code => "1",
      :area_code => "555",
      :central_office_code => "123",
      :subscriber_number => "4567",
      :extension => nil,
    },
    '+15551234567' => {
      :country_code => "1",
      :area_code => "555",
      :central_office_code => "123",
      :subscriber_number => "4567",
      :extension => nil,
    },
    '02612000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '00492612000' => {
      :country_code => "49",
      :area_code => "261",
      :central_office_code => nil,
      :subscriber_number => "2000",
      :extension => nil,
    },
    '2000' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => nil,
      :extension => "2000",
    },
    '99' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => nil,
      :extension => "99",
    },
    '5' => {
      :country_code => nil,
      :area_code => nil,
      :central_office_code => nil,
      :subscriber_number => nil,
      :extension => "5",
    },
    '' => nil,
    nil => nil,
    '++++' => nil,
    '###' => nil,
    'äöü' => nil,
    false => nil,
    true => nil,  # true.to_s == "true"  # invalid number
  }.each_pair do |number, expected|
    test "should parse number #{number.inspect} correctly for a specific tenant" do
      # load some country codes:
      usa     = Country.create(:name => "United States of America", :country_code => "1",  :international_call_prefix => "011", :trunk_prefix => "1" )
      germany = Country.create(:name => "Germany", :country_code => "49",  :international_call_prefix => "00", :trunk_prefix => "0" )
      cuba    = Country.create(:name => "Cuba", :country_code => "53",  :international_call_prefix => "119", :trunk_prefix => "" )
      # load some area codes:
      AreaCode.create(:country => germany, :name => "Koblenz am Rhein", :area_code => "261")
      AreaCode.create(:country => germany, :name => "Neuwied", :area_code => "2631")
      AreaCode.create(:country => germany, :name => "Berlin", :area_code => "30")
      AreaCode.create(:country => germany, :name => "Hamburg", :area_code => "40")
      AreaCode.create(:country => germany, :name => "Hohenmocker", :area_code => "39993")
      
      # create a tenant
      tenant = FactoryGirl.create(:tenant, :country_id => germany.id)
      # create some extensions
      internal_extension_range = tenant.phone_number_ranges.create(:name => GsParameter.get('INTERNAL_EXTENSIONS'))
      ['2000', '2001', '2003', '2004', '2005', '2006', '2007', '2008', '2009', '2010', '5', '99'].each do |extension|
        internal_extension_range.phone_numbers.create(:name => "Extension #{extension}", :number => extension)
      end
      
      assert_equal expected, PhoneNumber.parse( number, tenant )
    end
  end
  
  # TODO: Test uniqueness of a phone_number when creating it.
  
  # test "has to be unique per sip_account" do
  #   germany = Country.create(:name => "Germany", :country_code => "49",  :international_call_prefix => "00", :trunk_prefix => "0" )
  #   Language.create(:name => 'Deutsch', :code => 'de')
  #   AreaCode.create(:country => germany, :name => "Bendorf", :area_code => "2622")

  #   @sip_domain = FactoryGirl.create(:sip_domain)

  #   @tenant = @sip_domain.tenants.build(:name => 'AMOOMA GmbH')
  #   @tenant.country  = Country.first
  #   @tenant.language = Language.first
  #   @tenant.internal_extension_ranges = '10-20'
  #   @tenant.save

  #   @tenant.generate_internal_extensions

  #   sip_account = @tenant.sip_accounts.build(FactoryGirl.create(:sip_account).attributes)
  #   phone_number = sip_account.phone_numbers.create(FactoryGirl.build(:phone_number, :number => '10').attributes)
  #   phone_number_evil = sip_account.phone_numbers.build(phone_number.attributes)
    
  #   assert phone_number.valid?
  #   assert !phone_number_evil.valid?
  # end
    
  # test "has to be unique per SIP domain even for different tenants" do
  #   provider_sip_domain = FactoryGirl.create(:sip_domain)
  #   tenants      = []
  #   sip_accounts = []
  #   2.times { |i|
  #     tenants[i] = provider_sip_domain.tenants.create(FactoryGirl.build(:tenant, :internal_extension_ranges => '10-20').attributes)
  #     tenants[i].generate_internal_extensions

  #     sip_accounts[i] = tenants[i].sip_accounts.build(FactoryGirl.build(:sip_account, :tenant_id => tenants[i].id).attributes)
  #     sip_accounts[i].phone_numbers.build(:number => '10')
  #   }
  #   sip_accounts[0].save
    
  #   assert   sip_accounts[0].valid?, 'Should be valid.'
  #   assert ! sip_accounts[1].valid?,
  #     "Shouldn't be possible to use the same phone number more than once per SIP domain."
      
  #   # Lets change the second phone_number for a positiv test:
  #   #
  #   sip_accounts[1].phone_numbers.first.number = '11'
  #   assert sip_accounts[1].valid?    
  # end  
  
end
