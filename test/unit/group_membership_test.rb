require 'test_helper'

class GroupMembershipTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GroupMembership.new.valid?
  end
end
