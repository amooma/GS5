require 'test_helper'

class AcdCallersControllerTest < ActionController::TestCase
  setup do
    @acd_caller = acd_callers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:acd_callers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create acd_caller" do
    assert_difference('AcdCaller.count') do
      post :create, acd_caller: @acd_caller.attributes
    end

    assert_redirected_to acd_caller_path(assigns(:acd_caller))
  end

  test "should show acd_caller" do
    get :show, id: @acd_caller.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @acd_caller.to_param
    assert_response :success
  end

  test "should update acd_caller" do
    put :update, id: @acd_caller.to_param, acd_caller: @acd_caller.attributes
    assert_redirected_to acd_caller_path(assigns(:acd_caller))
  end

  test "should destroy acd_caller" do
    assert_difference('AcdCaller.count', -1) do
      delete :destroy, id: @acd_caller.to_param
    end

    assert_redirected_to acd_callers_path
  end
end
