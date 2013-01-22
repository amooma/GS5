require 'test_helper'

class ManufacturersControllerTest < ActionController::TestCase
  setup do
    @tenant = FactoryGirl.create(:tenant)
    @user  = FactoryGirl.create(:user)
    
    @tenant.tenant_memberships.create(:user_id => @user.id)
    
    @user.update_attributes!(:current_tenant_id => @tenant.id)

    @manufacturer = FactoryGirl.create(:manufacturer)
    
    @expected_status_if_not_authorized = :redirect
  end
  
  test "should not do anything for a normal user" do
    session[:user_id] = @user.id
    get :index
    assert_response :redirect
    
    get :new
    assert_response :redirect
    
    get :show, id: @manufacturer.to_param
    assert_response :redirect
    
    get :edit, id: @manufacturer.to_param
    assert_response :redirect
  end

  # Maybe some sort of SuperUser Group should have access.
  # Needs some more thinking.
  #
  # test "should get index" do
  #   session[:user_id] = @user.id
  #   get :index
  #   assert_response :success
  #   assert_not_nil assigns(:manufacturers)
  # end
  # 
  # test "should get new" do
  #   get :new
  #   assert_response :success
  # end
  # 
  # test "should create manufacturer" do
  #   assert_difference('Manufacturer.count') do
  #     post :create, manufacturer: FactoryGirl.build(:manufacturer).attributes
  #   end
  # 
  #   assert_redirected_to manufacturer_path(assigns(:manufacturer))
  # end
  # 
  # test "should show manufacturer" do
  #   get :show, id: @manufacturer.to_param
  #   assert_response :success
  # end
  # 
  # test "should get edit" do
  #   get :edit, id: @manufacturer.to_param
  #   assert_response :success
  # end
  # 
  # test "should update manufacturer" do
  #   put :update, id: @manufacturer.to_param, manufacturer: @manufacturer.attributes
  #   assert_redirected_to manufacturer_path(assigns(:manufacturer))
  # end
  # 
  # test "should destroy manufacturer" do
  #   assert_difference('Manufacturer.count', -1) do
  #     delete :destroy, id: @manufacturer.to_param
  #   end
  # 
  #   assert_redirected_to manufacturers_path
  # end
end
