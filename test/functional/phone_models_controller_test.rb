require 'test_helper'

class PhoneModelsControllerTest < ActionController::TestCase
  
  setup do
    # Create a tenant:
    @tenant = FactoryGirl.create(:tenant)
    
    # Create a User who is member of the Tenant but has no special rights:
    @user   = FactoryGirl.create(:user)
    @tenant.tenant_memberships.create(:user_id => @user.id)
    @user.update_attributes!(:current_tenant_id => @tenant.id)
    
    # Create a User who is member of the Tenant and has super admin rights:
    @super_admin = FactoryGirl.create(:user)
    @tenant.tenant_memberships.create(:user_id => @super_admin.id)
    @super_admin.update_attributes!(:current_tenant_id => @tenant.id)
    
    # Create a PhoneModel
    #
    @phone_model = FactoryGirl.create(:phone_model)
  end
  
  [ '@user.id', '' ].each do |user_id_code|
    # Note: Do *not* actually create the user outside of tests.
    
    explanation = user_id_code.blank? ?
      "if not logged in" :
      "if logged in as an ordinary user"
    
    test "should not get index #{explanation}" do
      session[:user_id] = eval( user_id_code )
      get :index, manufacturer_id: @phone_model.manufacturer_id
      assert_response :redirect
    end
    
    test "should not get new #{explanation}" do
      session[:user_id] = eval( user_id_code )
      get :new, manufacturer_id: @phone_model.manufacturer_id
      assert_response :redirect
    end
    
    test "should not create phone_model #{explanation}" do
      session[:user_id] = eval( user_id_code )
      
      assert_no_difference('PhoneModel.count') do
        post :create, manufacturer_id: @phone_model.manufacturer_id, phone_model: FactoryGirl.build(:phone_model,
          :manufacturer_id => @phone_model.manufacturer_id).attributes
      end
    end
     
    test "should not show phone_model #{explanation}" do
      session[:user_id] = eval( user_id_code )
      get :show, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
      assert_response :redirect
    end
     
    test "should not get edit #{explanation}" do
      session[:user_id] = eval( user_id_code )
      get :edit, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
      assert_response :redirect
    end

    test "should not update phone_model #{explanation}" do
      session[:user_id] = eval( user_id_code )
      
      # save the old name:
      old_name = PhoneModel.find(@phone_model.id).name
      # try to make an update:
      put :update, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param, phone_model: @phone_model.attributes.merge({
        'name' => @phone_model.name.reverse
      })
      # check that the update didn't work:
      assert_equal old_name, PhoneModel.find(@phone_model.id).name
      
      assert_response :redirect
    end
     
    test "should not destroy phone_model #{explanation}" do
      session[:user_id] = eval( user_id_code )
      
      assert_no_difference('PhoneModel.count') do
        delete :destroy, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
      end
      assert_response :redirect
    end
    
  end
  
  
  test "should get index as super admin" do
    session[:user_id] = @super_admin.id
    get :index, manufacturer_id: @phone_model.manufacturer_id
    assert_response :success
    assert_not_nil assigns(:phone_models)
  end
  
  test "should get new as super admin" do
    session[:user_id] = @super_admin.id
    get :new, manufacturer_id: @phone_model.manufacturer_id
    assert_response :success
  end
  
  
  # # We don't have access to manufacturer_id. We'll need to
  # # add routes first.
  # test "should create phone_model as super admin" do
  #   assert_difference('PhoneModel.count') do
  #     post :create, phone_model: FactoryGirl.build(:phone_model,
  #       :manufacturer_id => @phone_model.manufacturer_id).attributes
  #   end
  # 
  #   assert_redirected_to manufacturer_phone_model_path( @phone_model.manufacturer_id, assigns(:phone_model))
  # end
  
  test "should show phone_model as super admin" do
    session[:user_id] = @super_admin.id
    get :show, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
    assert_response :success
  end
  
  test "should get edit as super admin" do
    session[:user_id] = @super_admin.id
    get :edit, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
    assert_response :success
  end
  
  test "should update phone_model as super admin" do
    session[:user_id] = @super_admin.id
    put :update, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param, phone_model: @phone_model.attributes
    assert_redirected_to manufacturer_phone_model_path( @phone_model.manufacturer_id, assigns(:phone_model))
  end
  
  test "should destroy phone_model as super admin" do
    session[:user_id] = @super_admin.id
    assert_difference('PhoneModel.count', -1) do
      delete :destroy, manufacturer_id: @phone_model.manufacturer_id, id: @phone_model.to_param
    end
    
    assert_redirected_to manufacturer_phone_models_path( @phone_model.manufacturer_id )
  end
  
end
