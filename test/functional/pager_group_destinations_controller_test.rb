require 'test_helper'

class PagerGroupDestinationsControllerTest < ActionController::TestCase
  setup do
    @pager_group_destination = pager_group_destinations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pager_group_destinations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pager_group_destination" do
    assert_difference('PagerGroupDestination.count') do
      post :create, pager_group_destination: @pager_group_destination.attributes
    end

    assert_redirected_to pager_group_destination_path(assigns(:pager_group_destination))
  end

  test "should show pager_group_destination" do
    get :show, id: @pager_group_destination.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pager_group_destination.to_param
    assert_response :success
  end

  test "should update pager_group_destination" do
    put :update, id: @pager_group_destination.to_param, pager_group_destination: @pager_group_destination.attributes
    assert_redirected_to pager_group_destination_path(assigns(:pager_group_destination))
  end

  test "should destroy pager_group_destination" do
    assert_difference('PagerGroupDestination.count', -1) do
      delete :destroy, id: @pager_group_destination.to_param
    end

    assert_redirected_to pager_group_destinations_path
  end
end
