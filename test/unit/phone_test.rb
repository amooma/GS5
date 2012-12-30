require 'test_helper'

class PhoneTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:phone).valid?
  end
  
  # test "should destroy_all phones_sip_accounts if the phoneable changed" do
  #   sip_domain = FactoryGirl.create(:sip_domain)
  #   tenant = sip_domain.tenants.create(FactoryGirl.build(:tenant).attributes)
  # 
  #   user1 = FactoryGirl.create(:user)
  #   user2 = FactoryGirl.create(:user)
  #   tenant.tenant_memberships.create(:user_id => user1.id)
  #   tenant.tenant_memberships.create(:user_id => user2.id)
  #   
  #   phone = FactoryGirl.create(:phone, :phoneable => tenant)
  #   
  #   # Nothing there
  #   #
  #   assert_equal 0, phone.sip_accounts.count
  #   
  #   # move the phone to user1
  #   #
  #   phone.phoneable = user1
  #   phone.save
  #   
  #   # create some sip_accounts associated to phone
  #   #
  #   3.times { FactoryGirl.create(:sip_account, :sip_accountable => user1, :tenant_id => tenant.id) }
  #   SipAccount.all.each do |sip_account|
  #     phone.phones_sip_accounts.create(:sip_account_id => sip_account.id)
  #   end
  #   
  #   # Should have 3 sip_accounts
  #   #
  #   assert_equal 3, phone.sip_accounts.count
  # 
  #   # Move to user2    
  #   phone.phoneable = user2
  #   phone.save
  #   
  #   # Should have 0 sip_accounts
  #   #
  #   assert_equal 0, phone.sip_accounts.count
  # end
  
end
