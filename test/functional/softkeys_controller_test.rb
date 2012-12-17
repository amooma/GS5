require 'test_helper'

class SoftkeysControllerTest < ActionController::TestCase
  setup do
    @softkey = softkeys(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:softkeys)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create softkey" do
    assert_difference('Softkey.count') do
      post :create, softkey: @softkey.attributes
    end

    assert_redirected_to softkey_path(assigns(:softkey))
  end

  test "should show softkey" do
    get :show, id: @softkey.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @softkey.to_param
    assert_response :success
  end

  test "should update softkey" do
    put :update, id: @softkey.to_param, softkey: @softkey.attributes
    assert_redirected_to softkey_path(assigns(:softkey))
  end

  test "should destroy softkey" do
    assert_difference('Softkey.count', -1) do
      delete :destroy, id: @softkey.to_param
    end

    assert_redirected_to softkeys_path
  end
end
