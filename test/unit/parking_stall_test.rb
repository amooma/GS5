require 'test_helper'

class ParkingStallTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert ParkingStall.new.valid?
  end
end
