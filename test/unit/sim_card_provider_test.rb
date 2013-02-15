require 'test_helper'

class SimCardProviderTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert SimCardProvider.new.valid?
  end
end
