require 'test_helper'

class GroupPermissionTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GroupPermission.new.valid?
  end
end
