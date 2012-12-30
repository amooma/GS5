require 'test_helper'

class PhoneBookEntriesControllerTest < ActionController::TestCase
  
  setup do
    @user1 = FactoryGirl.create(:user)
    pb = @user1.phone_books.first
    @user1_phone_book_entry = FactoryGirl.create(
      :phone_book_entry,
      :phone_book_id => pb.id
    )
    
    @expected_status_if_not_authorized = :redirect
  end

  test "should not get index (not logged in)" do
    get :index
    assert_response @expected_status_if_not_authorized
  end
  
  test "should get index" do
    session[:user_id] = @user1.id
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_book_entries)
  end
  
  
#   test "should get new" do
#     get :new
#     assert_response :success
#   end
  
  test "should not have a route for new" do
    assert_raises(ActionController::RoutingError) {
      get :new
    }
  end
  
# 
#   test "should create phone_book_entry" do
#     assert_difference('PhoneBookEntry.count') do
#       post :create, phone_book_entry: @user1_phone_book_entry.attributes
#     end
# 
#     assert_redirected_to phone_book_entry_path(assigns(:phone_book_entry))
#   end
# 
   test "should not show phone_book_entry (not logged in)" do
     get :show, id: @user1_phone_book_entry.to_param
     assert_response @expected_status_if_not_authorized
   end
   
   test "should show phone_book_entry without nesting" do
     session[:user_id] = @user1.id
     get :show, id: @user1_phone_book_entry.to_param
     assert_response :success
   end
   
   test "should show phone_book_entry nested in phone_book" do
     session[:user_id] = @user1.id
     get :show, phone_book_id: @user1_phone_book_entry.phone_book.id, id: @user1_phone_book_entry.to_param
     assert_response :success
   end
# 
#   test "should get edit" do
#     get :edit, id: @user1_phone_book_entry.to_param
#     assert_response :success
#   end
  
  test "should not have a route for edit" do
    assert_raises(ActionController::RoutingError) {
      get :edit, id: @user1_phone_book_entry.to_param
    }
  end
  
# 
#   test "should update phone_book_entry" do
#     put :update, id: @user1_phone_book_entry.to_param, phone_book_entry: @user1_phone_book_entry.attributes
#     assert_redirected_to phone_book_entry_path(assigns(:phone_book_entry))
#   end
  
  test "should not have a route for update" do
    assert_raises(ActionController::RoutingError) {
      put :update, id: @user1_phone_book_entry.to_param, phone_book_entry: @user1_phone_book_entry.attributes
    }
  end
  
# 
#   test "should destroy phone_book_entry" do
#     assert_difference('PhoneBookEntry.count', -1) do
#       delete :destroy, id: @user1_phone_book_entry.to_param
#     end
#     assert_redirected_to phone_book_entries_path
#   end
  
  test "should not have a route for destroy" do
    assert_raises(ActionController::RoutingError) {
      delete :destroy, id: @user1_phone_book_entry.to_param
    }
  end
  
end
