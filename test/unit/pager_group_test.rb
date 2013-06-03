require 'test_helper'

class PagerGroupTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert PagerGroup.new.valid?
  end
end
