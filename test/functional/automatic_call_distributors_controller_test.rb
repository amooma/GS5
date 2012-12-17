require 'test_helper'

class AutomaticCallDistributorsControllerTest < ActionController::TestCase
  setup do
    @automatic_call_distributor = automatic_call_distributors(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:automatic_call_distributors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create automatic_call_distributor" do
    assert_difference('AutomaticCallDistributor.count') do
      post :create, automatic_call_distributor: @automatic_call_distributor.attributes
    end

    assert_redirected_to automatic_call_distributor_path(assigns(:automatic_call_distributor))
  end

  test "should show automatic_call_distributor" do
    get :show, id: @automatic_call_distributor.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @automatic_call_distributor.to_param
    assert_response :success
  end

  test "should update automatic_call_distributor" do
    put :update, id: @automatic_call_distributor.to_param, automatic_call_distributor: @automatic_call_distributor.attributes
    assert_redirected_to automatic_call_distributor_path(assigns(:automatic_call_distributor))
  end

  test "should destroy automatic_call_distributor" do
    assert_difference('AutomaticCallDistributor.count', -1) do
      delete :destroy, id: @automatic_call_distributor.to_param
    end

    assert_redirected_to automatic_call_distributors_path
  end
end
