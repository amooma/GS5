require 'test_helper'

class CallRouteTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert CallRoute.new.valid?
  end
end
