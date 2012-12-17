require 'test_helper'

class PhoneBooksControllerTest < ActionController::TestCase
  setup do
    @tenant = Factory.create(:tenant)
    @admins = @tenant.user_groups.find_or_create_by_name('Admins')
    @users = @tenant.user_groups.find_or_create_by_name('Users')
    @user  = Factory.create(:user)
    
    @tenant.users << @user
    @users.users << @user
        
    @personal_phone_book = Factory.create(:phone_book,
    	:phone_bookable_type => @user.class.to_s,
    	:phone_bookable_id   => @user.id
    )
    phone_book_entry = Factory.create(:phone_book_entry)
    @personal_phone_book.phone_book_entries << phone_book_entry

    @expected_status_if_not_authorized = :redirect
    
    session[:user_id] = @user.id
  end

  test "should get index" do
    get :index, user_id: @user.id
    assert_response :success
    assert_not_nil assigns(:phone_books)
  end

  test "should get new" do
    get :new, user_id: @user.id
    assert_response :success
  end

  test "should create phone_book" do
    phone_book2 = Factory.build(:phone_book,
      :phone_bookable_type => @user.class.to_s,
      :phone_bookable_id   => @user.id
    )
    assert_difference('PhoneBook.count') do
      post :create, phone_book: phone_book2.attributes, user_id: @user.id
    end
    assert_redirected_to( user_phone_book_path( @user, assigns(:phone_book)))
  end

  test "should show phone_book" do
    get :show, id: @personal_phone_book.to_param, user_id: @user.id
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @personal_phone_book.to_param, user_id: @user.id
    assert_response :success
  end

  test "should update phone_book" do
    put :update, id: @personal_phone_book.to_param, phone_book: @personal_phone_book.attributes, user_id: @user.id
    assert_redirected_to( user_phone_book_path(@user, assigns(:phone_book)))
  end

  # TODO: Fix this test
  #
  # test "should destroy phone_book" do
  #   assert_difference('PhoneBook.count', -1) do
  #     delete :destroy, id: @personal_phone_book.to_param, user_id: @user.id
  #   end
  #   assert_redirected_to( user_phone_books_path( @user ))
  # end
  
end
