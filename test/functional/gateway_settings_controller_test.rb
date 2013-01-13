require 'test_helper'

class GatewaySettingsControllerTest < ActionController::TestCase
  setup do
    @gateway_setting = gateway_settings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gateway_settings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gateway_setting" do
    assert_difference('GatewaySetting.count') do
      post :create, gateway_setting: @gateway_setting.attributes
    end

    assert_redirected_to gateway_setting_path(assigns(:gateway_setting))
  end

  test "should show gateway_setting" do
    get :show, id: @gateway_setting.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gateway_setting.to_param
    assert_response :success
  end

  test "should update gateway_setting" do
    put :update, id: @gateway_setting.to_param, gateway_setting: @gateway_setting.attributes
    assert_redirected_to gateway_setting_path(assigns(:gateway_setting))
  end

  test "should destroy gateway_setting" do
    assert_difference('GatewaySetting.count', -1) do
      delete :destroy, id: @gateway_setting.to_param
    end

    assert_redirected_to gateway_settings_path
  end
end
