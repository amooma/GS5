require 'test_helper'

class OuiTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:oui).valid?
  end

  def test_that_the_initial_state_should_be_active
    @oui = FactoryGirl.create(:oui)
    assert_equal 'active', @oui.state
    assert @oui.active?
  end

end
