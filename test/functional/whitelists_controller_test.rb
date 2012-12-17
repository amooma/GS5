require 'test_helper'

class WhitelistsControllerTest < ActionController::TestCase
  setup do
    @whitelist = whitelists(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:whitelists)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create whitelist" do
    assert_difference('Whitelist.count') do
      post :create, whitelist: @whitelist.attributes
    end

    assert_redirected_to whitelist_path(assigns(:whitelist))
  end

  test "should show whitelist" do
    get :show, id: @whitelist.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @whitelist.to_param
    assert_response :success
  end

  test "should update whitelist" do
    put :update, id: @whitelist.to_param, whitelist: @whitelist.attributes
    assert_redirected_to whitelist_path(assigns(:whitelist))
  end

  test "should destroy whitelist" do
    assert_difference('Whitelist.count', -1) do
      delete :destroy, id: @whitelist.to_param
    end

    assert_redirected_to whitelists_path
  end
end
