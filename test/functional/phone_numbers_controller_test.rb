require 'test_helper'

class PhoneNumbersControllerTest < ActionController::TestCase
  
  setup do
    @tenant = FactoryGirl.create(:tenant)
    @user   = FactoryGirl.create(:user)
    
    @tenant.tenant_memberships.create(:user_id => @user.id)
    
    @user.update_attributes!(:current_tenant_id => @tenant.id)
    
    @private_phone_book = @user.phone_books.first

    @private_phone_book_entry = FactoryGirl.create(
      :phone_book_entry,
      :phone_book => @private_phone_book
    )
    @phone_number = FactoryGirl.create(
      :phone_number,
      :phone_numberable => @private_phone_book_entry
    )
    
    @expected_status_if_not_authorized = :redirect
  end
  
  
  test "should get index" do
    session[:user_id] = @user.id
    get :index, phone_book_entry_id: @private_phone_book_entry.id
    assert_response :success
    assert_not_nil assigns(:phone_numbers)
  end
  
  test "should not get index (not logged in)" do
    get :index, phone_book_entry_id: @private_phone_book_entry.id
    assert_response @expected_status_if_not_authorized
  end
  
  test "should get new" do
    session[:user_id] = @user.id
    get :new, phone_book_entry_id: @private_phone_book_entry.id
    assert_response :success
  end
  
  # test "should not get new (not logged in)" do
  #   get :new, phone_book_entry_id: @private_phone_book_entry.id
  #   assert_response @expected_status_if_not_authorized
  # end
  
  # test "should create phone_number" do
  #   session[:user_id] = @user.id
  #   assert_difference('PhoneNumber.count') do
  #     post :create, phone_book_entry_id: @private_phone_book_entry.id, phone_number: @phone_number.attributes
  #   end
  #   assert_redirected_to( phone_book_entry_phone_number_path( assigns(:phone_number)))
  # end
  # 
  # test "should not create phone_number (not logged in)" do
  #   assert_no_difference('PhoneNumber.count') do
  #     post :create, phone_book_entry_id: @private_phone_book_entry.id, phone_number: @phone_number.attributes
  #   end
  #   assert_response @expected_status_if_not_authorized
  # end
  
  test "should show phone_number" do
    session[:user_id] = @user.id
    get :show, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    assert_response :success
  end
  
  test "should not show phone_number (not logged in)" do
    get :show, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    assert_response @expected_status_if_not_authorized
  end
  
  
  test "should get edit" do
    session[:user_id] = @user.id
    get :edit, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    assert_response :success
  end
  
  test "should not get edit (not logged in)" do
    get :edit, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    assert_response @expected_status_if_not_authorized
  end
  
  test "should update phone_number" do
    session[:user_id] = @user.id
    put :update, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param, phone_number: @phone_number.attributes
    assert_redirected_to( phone_book_entry_phone_number_path( assigns(:phone_number)))
  end
  
  test "should not update phone_number (not logged in)" do
    put :update, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param, phone_number: @phone_number.attributes
    assert_response @expected_status_if_not_authorized
  end
  
  test "should destroy phone_number" do
    session[:user_id] = @user.id
    assert_difference('PhoneNumber.count', -1) do
      delete :destroy, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    end
    assert_redirected_to( phone_book_entry_phone_numbers_path() )
  end
  
  test "should not destroy phone_number (not logged in)" do
    assert_no_difference('PhoneNumber.count') do
      delete :destroy, phone_book_entry_id: @private_phone_book_entry.id, id: @phone_number.to_param
    end
    assert_response @expected_status_if_not_authorized
  end
  
end
