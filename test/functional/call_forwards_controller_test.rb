require 'test_helper'

class CallForwardsControllerTest < ActionController::TestCase
  
  setup do
    @user = FactoryGirl.create(:user)
    
    #@tenant = FactoryGirl.create(:tenant)
    #@tenant.tenant_memberships.create(:user_id => @user.id)
    #@user.update_attributes!(:current_tenant_id => @tenant.id)
    
    @sip_account = FactoryGirl.create(
      :sip_account,
      :sip_accountable => @user,
    )
    @user.sip_accounts << @sip_account
    @sip_account = @user.sip_accounts.last
    
    @phone_number = FactoryGirl.create(
      :phone_number,
      :phone_numberable => @sip_account,
    )
    @sip_account.phone_numbers << @phone_number
    @phone_number = @sip_account.phone_numbers.last
    
    @call_forward = FactoryGirl.create(
      :call_forward,
      :phone_number => @phone_number,
    )
    @phone_number.call_forwards << @call_forward
    @call_forward = @phone_number.call_forwards.last
  end
  
  test "should get index" do
    session[:user_id] = @user.id
    get :index,
      :phone_number_id => @phone_number.to_param
    assert_response :success
    assert_not_nil assigns(:call_forwards)
  end
  
  test "should get new" do
    get :new,
      :phone_number_id => @phone_number.to_param
    assert_response :success
  end
  
  #TODO
#   test "should create call_forward" do
#     assert_difference('CallForward.count') do
#       post :create,
#         :phone_number_id => @phone_number.to_param,
#         :call_forward => FactoryGirl.attributes_for(
#           :call_forward
#         )
#     end
#     assert_redirected_to( phone_number_call_forward_path( @phone_number, @call_forward ) )
#   end
  
  test "should show call_forward" do
    session[:user_id] = @user.id
    get :show,
      :phone_number_id => @phone_number.to_param,
      :id => @call_forward.to_param
    assert_response :success
  end
  
  test "should get edit" do
    get :edit,
      :phone_number_id => @phone_number.to_param,
      :id => @call_forward.to_param
    assert_response :success
  end
  
  test "should update call_forward" do
    put :update,
      :phone_number_id => @phone_number.to_param,
      :id => @call_forward.to_param, call_forward: @call_forward.attributes
    assert_redirected_to( phone_number_call_forward_path( @phone_number, @call_forward ) )
  end
  
  test "should destroy call_forward" do
    assert_difference('CallForward.count', -1) do
      delete :destroy,
        :phone_number_id => @phone_number.to_param,
        :id => @call_forward.to_param
    end
    assert_redirected_to( phone_number_call_forwards_path( @phone_number ) )
  end
  
end
