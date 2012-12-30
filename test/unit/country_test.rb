require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:country).valid?
  end
end
