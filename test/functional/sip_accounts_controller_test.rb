require 'test_helper'

class SipAccountsControllerTest < ActionController::TestCase
  
  setup do
    @tenant = Factory.create(:tenant)
    @user = Factory.create(:user)
    @tenant.tenant_memberships.create(:user_id => @user.id)
    @sip_account    = @user.sip_accounts.create( Factory.build(:sip_account).attributes )
    
    @parent_param = @sip_account.sip_accountable_type.foreign_key.to_sym
    @parent_id    = @sip_account.sip_accountable.id
  end
  
  test "should get index" do
    session[:user_id] = @user.id
    get :index,
      @parent_param => @parent_id
    assert_response :success
    assert_not_nil assigns(:sip_accounts)
  end
  
  test "should get new" do
    session[:user_id] = @user.id
    get :new,
      @parent_param => @parent_id
    assert_response :success
  end
  
  test "should create sip_account" do
    session[:user_id] = @user.id
    assert_difference('SipAccount.count') do
      post :create,
        @parent_param => @parent_id,
        sip_account: Factory.attributes_for(:sip_account)
    end
  end
  
  test "should show sip_account" do
    session[:user_id] = @user.id
    get :show,
      @parent_param => @parent_id,
      id: @sip_account.to_param
    assert_response :success
  end
  
  test "should get edit" do
    session[:user_id] = @user.id
    get :edit,
      @parent_param => @parent_id,
      id: @sip_account.to_param
    assert_response :success
  end
  
  test "should update sip_account" do
    session[:user_id] = @user.id
    put :update,
      @parent_param => @parent_id,
      id: @sip_account.to_param,
      sip_account: @sip_account.attributes
    # TODO Find the right redirect/answer.
    #assert_redirected_to method( :"#{@sip_account.sip_accountable_type.underscore}_sip_account_path" ).( @sip_account.sip_accountable, @sip_account )
  end
  
  test "should destroy sip_account" do
    session[:user_id] = @user.id
    assert_difference('SipAccount.count', -1) do
      delete :destroy,
        @parent_param => @parent_id,
        id: @sip_account.to_param
    end
    # TODO Find the right redirect/answer.
    #assert_redirected_to method( :"#{@sip_account.sip_accountable_type.underscore}_sip_accounts_path" ).( @sip_account.sip_accountable )
  end
  
end
