require 'test_helper'

class IntrudersControllerTest < ActionController::TestCase
  setup do
    @intruder = intruders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:intruders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create intruder" do
    assert_difference('Intruder.count') do
      post :create, intruder: @intruder.attributes
    end

    assert_redirected_to intruder_path(assigns(:intruder))
  end

  test "should show intruder" do
    get :show, id: @intruder.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @intruder.to_param
    assert_response :success
  end

  test "should update intruder" do
    put :update, id: @intruder.to_param, intruder: @intruder.attributes
    assert_redirected_to intruder_path(assigns(:intruder))
  end

  test "should destroy intruder" do
    assert_difference('Intruder.count', -1) do
      delete :destroy, id: @intruder.to_param
    end

    assert_redirected_to intruders_path
  end
end
