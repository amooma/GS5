require 'test_helper'

class SipDomainTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert Factory.build(:sip_domain).valid?
  end
  
end
