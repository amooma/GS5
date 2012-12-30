require 'test_helper'

class PhoneModelTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:phone_model).valid?
  end
  
end
