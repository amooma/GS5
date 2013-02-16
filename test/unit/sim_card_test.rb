require 'test_helper'

class SimCardTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert SimCard.new.valid?
  end
end
