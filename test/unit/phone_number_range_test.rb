require 'test_helper'

class PhoneNumberRangeTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:phone_number_range).valid?
  end
  
end
