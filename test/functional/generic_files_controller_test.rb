require 'test_helper'

class GenericFilesControllerTest < ActionController::TestCase
  setup do
    @generic_file = generic_files(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:generic_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create generic_file" do
    assert_difference('GenericFile.count') do
      post :create, generic_file: @generic_file.attributes
    end

    assert_redirected_to generic_file_path(assigns(:generic_file))
  end

  test "should show generic_file" do
    get :show, id: @generic_file.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @generic_file.to_param
    assert_response :success
  end

  test "should update generic_file" do
    put :update, id: @generic_file.to_param, generic_file: @generic_file.attributes
    assert_redirected_to generic_file_path(assigns(:generic_file))
  end

  test "should destroy generic_file" do
    assert_difference('GenericFile.count', -1) do
      delete :destroy, id: @generic_file.to_param
    end

    assert_redirected_to generic_files_path
  end
end
