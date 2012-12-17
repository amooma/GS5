require 'test_helper'

class PhoneSipAccountsControllerTest < ActionController::TestCase
  setup do
    @phone_sip_account = phone_sip_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_sip_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phone_sip_account" do
    assert_difference('PhoneSipAccount.count') do
      post :create, phone_sip_account: @phone_sip_account.attributes
    end

    assert_redirected_to phone_sip_account_path(assigns(:phone_sip_account))
  end

  test "should show phone_sip_account" do
    get :show, id: @phone_sip_account.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @phone_sip_account.to_param
    assert_response :success
  end

  test "should update phone_sip_account" do
    put :update, id: @phone_sip_account.to_param, phone_sip_account: @phone_sip_account.attributes
    assert_redirected_to phone_sip_account_path(assigns(:phone_sip_account))
  end

  test "should destroy phone_sip_account" do
    assert_difference('PhoneSipAccount.count', -1) do
      delete :destroy, id: @phone_sip_account.to_param
    end

    assert_redirected_to phone_sip_accounts_path
  end
end
