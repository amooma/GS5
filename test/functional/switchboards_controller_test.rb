require 'test_helper'

class SwitchboardsControllerTest < ActionController::TestCase
  setup do
    @switchboard = switchboards(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:switchboards)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create switchboard" do
    assert_difference('Switchboard.count') do
      post :create, switchboard: @switchboard.attributes
    end

    assert_redirected_to switchboard_path(assigns(:switchboard))
  end

  test "should show switchboard" do
    get :show, id: @switchboard.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @switchboard.to_param
    assert_response :success
  end

  test "should update switchboard" do
    put :update, id: @switchboard.to_param, switchboard: @switchboard.attributes
    assert_redirected_to switchboard_path(assigns(:switchboard))
  end

  test "should destroy switchboard" do
    assert_difference('Switchboard.count', -1) do
      delete :destroy, id: @switchboard.to_param
    end

    assert_redirected_to switchboards_path
  end
end
