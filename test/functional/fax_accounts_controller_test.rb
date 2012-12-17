require 'test_helper'

class FaxAccountsControllerTest < ActionController::TestCase
  setup do
    @fax_account = fax_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fax_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fax_account" do
    assert_difference('FaxAccount.count') do
      post :create, fax_account: @fax_account.attributes
    end

    assert_redirected_to fax_account_path(assigns(:fax_account))
  end

  test "should show fax_account" do
    get :show, id: @fax_account.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fax_account.to_param
    assert_response :success
  end

  test "should update fax_account" do
    put :update, id: @fax_account.to_param, fax_account: @fax_account.attributes
    assert_redirected_to fax_account_path(assigns(:fax_account))
  end

  test "should destroy fax_account" do
    assert_difference('FaxAccount.count', -1) do
      delete :destroy, id: @fax_account.to_param
    end

    assert_redirected_to fax_accounts_path
  end
end
