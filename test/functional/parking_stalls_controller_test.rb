require 'test_helper'

class ParkingStallsControllerTest < ActionController::TestCase
  setup do
    @parking_stall = parking_stalls(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:parking_stalls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create parking_stall" do
    assert_difference('ParkingStall.count') do
      post :create, parking_stall: @parking_stall.attributes
    end

    assert_redirected_to parking_stall_path(assigns(:parking_stall))
  end

  test "should show parking_stall" do
    get :show, id: @parking_stall.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @parking_stall.to_param
    assert_response :success
  end

  test "should update parking_stall" do
    put :update, id: @parking_stall.to_param, parking_stall: @parking_stall.attributes
    assert_redirected_to parking_stall_path(assigns(:parking_stall))
  end

  test "should destroy parking_stall" do
    assert_difference('ParkingStall.count', -1) do
      delete :destroy, id: @parking_stall.to_param
    end

    assert_redirected_to parking_stalls_path
  end
end
