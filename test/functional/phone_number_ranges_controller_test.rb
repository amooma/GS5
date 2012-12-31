require 'test_helper'

class PhoneNumberRangesControllerTest < ActionController::TestCase
  
  #TODO Uncomment tests once the views are implemented.
  
  setup do
    @phone_number_range = FactoryGirl.create(:phone_number_range)
  end
  
  test "should get index" do
    get :index,
      :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param)
    assert_response :success
    assert_not_nil assigns(:phone_number_ranges)
  end
  
#   test "should get new" do
#     get :new,
#       :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param)
#     assert_response :success
#   end
  
#   test "should create phone_number_range" do
#     assert_difference('PhoneNumberRange.count') do
#       post :create,
#         :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param),
#         :phone_number_range => @phone_number_range.attributes
#     end
#     assert_redirected_to(
#       method( :"#{@phone_number_range.phone_number_rangeable_type.underscore}_phone_number_range_path" ).(
#         @phone_number_range.phone_number_rangeable,
#         @phone_number_range
#       )
#     )
#   end
  
#   test "should show phone_number_range" do
#     get :show,
#       :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param),
#       :id => @phone_number_range.to_param
#     assert_response :success
#   end
  
#   test "should get edit" do
#     get :edit,
#       :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param),
#       :id => @phone_number_range.to_param
#     assert_response :success
#   end
  
  test "should update phone_number_range" do
    put :update,
      :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param),
      :id => @phone_number_range.to_param,
      :phone_number_range => @phone_number_range.attributes
#     assert_redirected_to(
#       method( :"#{@phone_number_range.phone_number_rangeable_type.underscore}_phone_number_range_path" ).(
#         @phone_number_range.phone_number_rangeable,
#         @phone_number_range
#       )
#     )
  end
  
#   test "should destroy phone_number_range" do
#     assert_difference('PhoneNumberRange.count', -1) do
#       delete :destroy,
#         :"#{@phone_number_range.phone_number_rangeable_type.underscore}_id" => @phone_number_range.phone_number_rangeable.try(:to_param),
#         :id => @phone_number_range.to_param
#     end
#     assert_redirected_to(
#       method( :"#{@phone_number_range.phone_number_rangeable_type.underscore}_phone_number_ranges_path" ).(
#         @phone_number_range.phone_number_rangeable
#       )
#     )
#   end
  
end
