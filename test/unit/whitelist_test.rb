require 'test_helper'

class WhitelistTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Whitelist.new.valid?
  end
end
