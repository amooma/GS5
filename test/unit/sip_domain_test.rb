require 'test_helper'

class SipDomainTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:sip_domain).valid?
  end
  
end
