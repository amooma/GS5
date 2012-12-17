require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert Factory.build(:tenant).valid?
  end
  
  def test_should_have_unique_name
    tenant = Factory.create(:tenant)
    assert !Factory.build(:tenant, :name => tenant.name).valid?
    assert Factory.build(:tenant, :name => "different_#{tenant.name}").valid?
  end
  
  def test_that_the_initial_state_should_be_active
    @tenant = Factory.create(:tenant)
    assert_equal 'active', @tenant.state
    assert @tenant.active?
  end
  
  def test_not_active_state_will_not_be_displayed
    @tenant = Factory.create(:tenant)
    assert_equal 1, Tenant.count
    
    @tenant.deactivate!
    assert_equal 0, Tenant.count
    assert_equal 1, Tenant.unscoped.count
    
    @tenant.activate!
    assert_equal 1, Tenant.count
    assert_equal Tenant.count, Tenant.unscoped.count
  end
  
end
