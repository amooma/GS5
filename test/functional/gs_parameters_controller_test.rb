require 'test_helper'

class GsParametersControllerTest < ActionController::TestCase
  setup do
    @gs_parameter = gs_parameters(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gs_parameters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gs_parameter" do
    assert_difference('GsParameter.count') do
      post :create, gs_parameter: @gs_parameter.attributes
    end

    assert_redirected_to gs_parameter_path(assigns(:gs_parameter))
  end

  test "should show gs_parameter" do
    get :show, id: @gs_parameter.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gs_parameter.to_param
    assert_response :success
  end

  test "should update gs_parameter" do
    put :update, id: @gs_parameter.to_param, gs_parameter: @gs_parameter.attributes
    assert_redirected_to gs_parameter_path(assigns(:gs_parameter))
  end

  test "should destroy gs_parameter" do
    assert_difference('GsParameter.count', -1) do
      delete :destroy, id: @gs_parameter.to_param
    end

    assert_redirected_to gs_parameters_path
  end
end
