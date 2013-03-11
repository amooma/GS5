require 'test_helper'

class SwitchboardEntryTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert SwitchboardEntry.new.valid?
  end
end
