require 'test_helper'

class CallthroughsControllerTest < ActionController::TestCase
  setup do
    @callthrough = callthroughs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:callthroughs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create callthrough" do
    assert_difference('Callthrough.count') do
      post :create, callthrough: @callthrough.attributes
    end

    assert_redirected_to callthrough_path(assigns(:callthrough))
  end

  test "should show callthrough" do
    get :show, id: @callthrough.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @callthrough.to_param
    assert_response :success
  end

  test "should update callthrough" do
    put :update, id: @callthrough.to_param, callthrough: @callthrough.attributes
    assert_redirected_to callthrough_path(assigns(:callthrough))
  end

  test "should destroy callthrough" do
    assert_difference('Callthrough.count', -1) do
      delete :destroy, id: @callthrough.to_param
    end

    assert_redirected_to callthroughs_path
  end
end
