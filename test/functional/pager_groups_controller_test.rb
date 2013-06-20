require 'test_helper'

class PagerGroupsControllerTest < ActionController::TestCase
  setup do
    @pager_group = pager_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pager_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pager_group" do
    assert_difference('PagerGroup.count') do
      post :create, pager_group: @pager_group.attributes
    end

    assert_redirected_to pager_group_path(assigns(:pager_group))
  end

  test "should show pager_group" do
    get :show, id: @pager_group.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pager_group.to_param
    assert_response :success
  end

  test "should update pager_group" do
    put :update, id: @pager_group.to_param, pager_group: @pager_group.attributes
    assert_redirected_to pager_group_path(assigns(:pager_group))
  end

  test "should destroy pager_group" do
    assert_difference('PagerGroup.count', -1) do
      delete :destroy, id: @pager_group.to_param
    end

    assert_redirected_to pager_groups_path
  end
end
