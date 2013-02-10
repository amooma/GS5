require 'test_helper'

class IntruderTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Intruder.new.valid?
  end
end
