require 'test_helper'

class AutomaticCallDistributorTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert AutomaticCallDistributor.new.valid?
  end
end
