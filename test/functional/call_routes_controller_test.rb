require 'test_helper'

class CallRoutesControllerTest < ActionController::TestCase
  setup do
    @call_route = call_routes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:call_routes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create call_route" do
    assert_difference('CallRoute.count') do
      post :create, call_route: @call_route.attributes
    end

    assert_redirected_to call_route_path(assigns(:call_route))
  end

  test "should show call_route" do
    get :show, id: @call_route.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @call_route.to_param
    assert_response :success
  end

  test "should update call_route" do
    put :update, id: @call_route.to_param, call_route: @call_route.attributes
    assert_redirected_to call_route_path(assigns(:call_route))
  end

  test "should destroy call_route" do
    assert_difference('CallRoute.count', -1) do
      delete :destroy, id: @call_route.to_param
    end

    assert_redirected_to call_routes_path
  end
end
