require 'test_helper'

class RouteElementTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert RouteElement.new.valid?
  end
end
