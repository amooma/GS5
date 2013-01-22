require 'test_helper'

class TriggerControllerTest < ActionController::TestCase
  test "should get voicemail" do
    get :voicemail
    assert_response :success
  end

  test "should get fax" do
    get :fax
    assert_response :success
  end

end
