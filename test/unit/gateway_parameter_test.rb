require 'test_helper'

class GatewayParameterTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GatewayParameter.new.valid?
  end
end
