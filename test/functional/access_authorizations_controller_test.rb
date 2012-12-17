require 'test_helper'

class AccessAuthorizationsControllerTest < ActionController::TestCase
  setup do
    @access_authorization = access_authorizations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:access_authorizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create access_authorization" do
    assert_difference('AccessAuthorization.count') do
      post :create, access_authorization: @access_authorization.attributes
    end

    assert_redirected_to access_authorization_path(assigns(:access_authorization))
  end

  test "should show access_authorization" do
    get :show, id: @access_authorization.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @access_authorization.to_param
    assert_response :success
  end

  test "should update access_authorization" do
    put :update, id: @access_authorization.to_param, access_authorization: @access_authorization.attributes
    assert_redirected_to access_authorization_path(assigns(:access_authorization))
  end

  test "should destroy access_authorization" do
    assert_difference('AccessAuthorization.count', -1) do
      delete :destroy, id: @access_authorization.to_param
    end

    assert_redirected_to access_authorizations_path
  end
end
