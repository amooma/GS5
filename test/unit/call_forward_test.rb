require 'test_helper'

class CallForwardTest < ActiveSupport::TestCase
  
  test "should have a valid factory" do
    assert Factory.build(:call_forward).valid?
  end
  
end
