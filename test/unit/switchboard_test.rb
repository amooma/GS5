require 'test_helper'

class SwitchboardTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Switchboard.new.valid?
  end
end
