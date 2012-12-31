require 'test_helper'

class GemeinschaftSetupTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:gemeinschaft_setup).valid?
  end
end
