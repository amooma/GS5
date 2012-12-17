require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @tenant = Factory.create(:tenant)
    @user  = Factory.create(:user)
    
    @tenant.tenant_memberships.create(:user_id => @user.id)
    
    @user.update_attributes!(:current_tenant_id => @tenant.id)
    
    @expected_status_if_not_authorized = :redirect
  end
  
  test "should get index" do
    session[:user_id] = @user.id
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end
  
  test "should get new" do
    session[:user_id] = nil
    get :new
    assert_response :success
  end

  # TODO Fix Test
  #
  # test "should create user" do
  #   session[:user_id] = nil
  #   assert_difference('User.count') do
  #     post :create, user: Factory.build(:user).attributes
  #   end
  # 
  # #  assert_redirected_to user_path(assigns(:user))
  # end
  
  test "should show user" do
    session[:user_id] = @user.id
    get :show, id: @user.to_param
    assert_response :success
  end
  
  
  test "should get edit" do
    session[:user_id] = @user.id
    get :edit, id: @user.to_param
    assert_response :success
  end
  
  test "should update user" do
    session[:user_id] = @user.id
    put :update, id: @user.to_param, user: @user.attributes
    assert_redirected_to user_path(assigns(:user))
  end
  
  test "should not destroy itself" do
    assert_no_difference('User.count') do
      delete :destroy, id: @user.to_param
    end
  
#    assert_redirected_to users_path
  end
end
