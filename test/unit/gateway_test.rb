require 'test_helper'

class GatewayTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Gateway.new.valid?
  end
end
