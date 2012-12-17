require 'test_helper'

class TenantMembershipTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert Factory.build(:tenant_membership).valid?
  end
  
  def test_that_the_initial_state_should_be_active
    @tenant_membership = Factory.create(:tenant_membership)
    assert_equal 'active', @tenant_membership.state
    assert @tenant_membership.active?
  end
  
end
