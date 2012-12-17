require 'test_helper'

class PhonesSipAccountsControllerTest < ActionController::TestCase
  
  setup do
    @phones_sip_account = Factory.create(:phones_sip_account)
  end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:phones_sip_accounts)
#   end
# 
#   test "should get new" do
#     get :new
#     assert_response :success
#   end
# 
#   test "should create phones_sip_account" do
#     assert_difference('PhonesSipAccount.count') do
#       post :create, phones_sip_account: @phones_sip_account.attributes
#     end
#     assert_redirected_to phones_sip_account_path(assigns(:phones_sip_account))
#   end
# 
#   test "should show phones_sip_account" do
#     get :show, id: @phones_sip_account.to_param
#     assert_response :success
#   end
# 
#   test "should get edit" do
#     get :edit, id: @phones_sip_account.to_param
#     assert_response :success
#   end
# 
#   test "should update phones_sip_account" do
#     put :update, id: @phones_sip_account.to_param, phones_sip_account: @phones_sip_account.attributes
#     assert_redirected_to phones_sip_account_path(assigns(:phones_sip_account))
#   end
# 
#   test "should destroy phones_sip_account" do
#     assert_difference('PhonesSipAccount.count', -1) do
#       delete :destroy, id: @phones_sip_account.to_param
#     end
#     assert_redirected_to phones_sip_accounts_path
#   end
  
end
