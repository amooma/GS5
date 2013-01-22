require 'test_helper'

class RouteElementsControllerTest < ActionController::TestCase
  setup do
    @route_element = route_elements(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:route_elements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create route_element" do
    assert_difference('RouteElement.count') do
      post :create, route_element: @route_element.attributes
    end

    assert_redirected_to route_element_path(assigns(:route_element))
  end

  test "should show route_element" do
    get :show, id: @route_element.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @route_element.to_param
    assert_response :success
  end

  test "should update route_element" do
    put :update, id: @route_element.to_param, route_element: @route_element.attributes
    assert_redirected_to route_element_path(assigns(:route_element))
  end

  test "should destroy route_element" do
    assert_difference('RouteElement.count', -1) do
      delete :destroy, id: @route_element.to_param
    end

    assert_redirected_to route_elements_path
  end
end
