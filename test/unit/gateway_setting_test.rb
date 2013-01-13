require 'test_helper'

class GatewaySettingTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GatewaySetting.new.valid?
  end
end
