require 'test_helper'

class GroupMembershipsControllerTest < ActionController::TestCase
  setup do
    @group_membership = group_memberships(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:group_memberships)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create group_membership" do
    assert_difference('GroupMembership.count') do
      post :create, group_membership: @group_membership.attributes
    end

    assert_redirected_to group_membership_path(assigns(:group_membership))
  end

  test "should show group_membership" do
    get :show, id: @group_membership.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @group_membership.to_param
    assert_response :success
  end

  test "should update group_membership" do
    put :update, id: @group_membership.to_param, group_membership: @group_membership.attributes
    assert_redirected_to group_membership_path(assigns(:group_membership))
  end

  test "should destroy group_membership" do
    assert_difference('GroupMembership.count', -1) do
      delete :destroy, id: @group_membership.to_param
    end

    assert_redirected_to group_memberships_path
  end
end
