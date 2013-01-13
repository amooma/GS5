require 'test_helper'

class GatewayParametersControllerTest < ActionController::TestCase
  setup do
    @gateway_parameter = gateway_parameters(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gateway_parameters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gateway_parameter" do
    assert_difference('GatewayParameter.count') do
      post :create, gateway_parameter: @gateway_parameter.attributes
    end

    assert_redirected_to gateway_parameter_path(assigns(:gateway_parameter))
  end

  test "should show gateway_parameter" do
    get :show, id: @gateway_parameter.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gateway_parameter.to_param
    assert_response :success
  end

  test "should update gateway_parameter" do
    put :update, id: @gateway_parameter.to_param, gateway_parameter: @gateway_parameter.attributes
    assert_redirected_to gateway_parameter_path(assigns(:gateway_parameter))
  end

  test "should destroy gateway_parameter" do
    assert_difference('GatewayParameter.count', -1) do
      delete :destroy, id: @gateway_parameter.to_param
    end

    assert_redirected_to gateway_parameters_path
  end
end
