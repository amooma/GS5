require 'test_helper'

class PageControllerTest < ActionController::TestCase
  
  #test "on a fresh system you should not get index but be redirected to the setup wizard" do
  test "should be redirected to setup wizard on a fresh system" do
    session[:user_id] = nil
    get :index
    assert_redirected_to wizards_new_initial_setup_path
  end
  
  
  test "a logged in user should get index" do
    @tenant = FactoryGirl.create(:tenant)
    @user  = FactoryGirl.create(:user)
    
    @tenant.users << @user
    
    session[:user_id] = @user.id
    get :index
    assert_response :success
  end

  test "a logged out user should be redirected to the login" do
    @tenant = FactoryGirl.create(:tenant)
    @user  = FactoryGirl.create(:user)
    
    @tenant.users << @user
    
    session[:user_id] = nil
    get :index
    assert_redirected_to log_in_path
  end

end
