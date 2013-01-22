require 'test_helper'

class SipAccountTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:sip_account).valid?
  end
  
  test "that the value_of_to_s field is filled" do
    sip_account = FactoryGirl.create(:sip_account)
    assert_equal sip_account.value_of_to_s, sip_account.to_s
  end
  
  test "should have a unique auth_name per sip_domain" do
    provider_sip_domain = FactoryGirl.create(:sip_domain)
    tenants      = []
    sip_accounts = []
    2.times { |i|
      tenants[i] = provider_sip_domain.tenants.create(FactoryGirl.build(:tenant).attributes)
      sip_accounts[i] = FactoryGirl.build(
        :sip_account,
        :sip_accountable => tenants[i],
        :auth_name => "somerandomauthname",
        :tenant_id => tenants[i].id
        )
    }
    sip_accounts[0].save!
    
    assert   sip_accounts[0].valid?
    assert ! sip_accounts[1].valid?,
      "Shouldn't be possible to use the same phone number more than once per SIP realm."
  end
  
end
