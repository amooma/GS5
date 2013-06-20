require 'test_helper'

class PagerGroupDestinationTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert PagerGroupDestination.new.valid?
  end
end
