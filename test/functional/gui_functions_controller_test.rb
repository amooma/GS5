require 'test_helper'

class GuiFunctionsControllerTest < ActionController::TestCase
  setup do
    @gui_function = gui_functions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gui_functions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gui_function" do
    assert_difference('GuiFunction.count') do
      post :create, gui_function: @gui_function.attributes
    end

    assert_redirected_to gui_function_path(assigns(:gui_function))
  end

  test "should show gui_function" do
    get :show, id: @gui_function.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gui_function.to_param
    assert_response :success
  end

  test "should update gui_function" do
    put :update, id: @gui_function.to_param, gui_function: @gui_function.attributes
    assert_redirected_to gui_function_path(assigns(:gui_function))
  end

  test "should destroy gui_function" do
    assert_difference('GuiFunction.count', -1) do
      delete :destroy, id: @gui_function.to_param
    end

    assert_redirected_to gui_functions_path
  end
end
