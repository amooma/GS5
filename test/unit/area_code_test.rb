require 'test_helper'

class AreaCodeTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert Factory.build(:area_code).valid?
  end
end
