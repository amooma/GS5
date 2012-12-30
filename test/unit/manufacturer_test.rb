require 'test_helper'

class ManufacturerTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:manufacturer).valid?
  end

  # StateMachine Tests:
  def test_that_the_initial_state_should_be_active
    @manufacturer = FactoryGirl.create(:manufacturer)
    assert_equal 'active', @manufacturer.state
    assert @manufacturer.active?
  end
  
  def test_not_active_state_will_not_be_displayed
    @manufacturer = FactoryGirl.create(:manufacturer)
    assert_equal 1, Manufacturer.count
    
    @manufacturer.deactivate!
    assert_equal 0, Manufacturer.count
    assert_equal 1, Manufacturer.unscoped.count
    
    @manufacturer.activate!
    assert_equal 1, Manufacturer.count
    assert_equal Manufacturer.count, Manufacturer.unscoped.count
  end
end
