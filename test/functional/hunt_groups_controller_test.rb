require 'test_helper'

class HuntGroupsControllerTest < ActionController::TestCase
  setup do
    @hunt_group = hunt_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:hunt_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create hunt_group" do
    assert_difference('HuntGroup.count') do
      post :create, hunt_group: @hunt_group.attributes
    end

    assert_redirected_to hunt_group_path(assigns(:hunt_group))
  end

  test "should show hunt_group" do
    get :show, id: @hunt_group.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @hunt_group.to_param
    assert_response :success
  end

  test "should update hunt_group" do
    put :update, id: @hunt_group.to_param, hunt_group: @hunt_group.attributes
    assert_redirected_to hunt_group_path(assigns(:hunt_group))
  end

  test "should destroy hunt_group" do
    assert_difference('HuntGroup.count', -1) do
      delete :destroy, id: @hunt_group.to_param
    end

    assert_redirected_to hunt_groups_path
  end
end
