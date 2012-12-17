require 'test_helper'

class HuntGroupMembersControllerTest < ActionController::TestCase
  setup do
    @hunt_group_member = hunt_group_members(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:hunt_group_members)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create hunt_group_member" do
    assert_difference('HuntGroupMember.count') do
      post :create, hunt_group_member: @hunt_group_member.attributes
    end

    assert_redirected_to hunt_group_member_path(assigns(:hunt_group_member))
  end

  test "should show hunt_group_member" do
    get :show, id: @hunt_group_member.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @hunt_group_member.to_param
    assert_response :success
  end

  test "should update hunt_group_member" do
    put :update, id: @hunt_group_member.to_param, hunt_group_member: @hunt_group_member.attributes
    assert_redirected_to hunt_group_member_path(assigns(:hunt_group_member))
  end

  test "should destroy hunt_group_member" do
    assert_difference('HuntGroupMember.count', -1) do
      delete :destroy, id: @hunt_group_member.to_param
    end

    assert_redirected_to hunt_group_members_path
  end
end
