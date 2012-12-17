require 'test_helper'

class Api::RowsControllerTest < ActionController::TestCase
  setup do
    @api_row = api_rows(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:api_rows)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create api_row" do
    assert_difference('Api::Row.count') do
      post :create, api_row: @api_row.attributes
    end

    assert_redirected_to api_row_path(assigns(:api_row))
  end

  test "should show api_row" do
    get :show, id: @api_row
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @api_row
    assert_response :success
  end

  test "should update api_row" do
    put :update, id: @api_row, api_row: @api_row.attributes
    assert_redirected_to api_row_path(assigns(:api_row))
  end

  test "should destroy api_row" do
    assert_difference('Api::Row.count', -1) do
      delete :destroy, id: @api_row
    end

    assert_redirected_to api_rows_path
  end
end
