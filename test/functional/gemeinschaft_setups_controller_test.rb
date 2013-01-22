require 'test_helper'

class GemeinschaftSetupsControllerTest < ActionController::TestCase
  
  setup do
    @gemeinschaft_setup = FactoryGirl.build(:gemeinschaft_setup)
  end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:gemeinschaft_setups)
#   end

  test "should get new" do
    get :new
    assert_response :success
  end

#   test "should create gemeinschaft_setup" do
#     assert_difference('GemeinschaftSetup.count') do
#       post :create,
#         gemeinschaft_setup: FactoryGirl.attributes_for(:gemeinschaft_setup)
#     end
#     assert_redirected_to gemeinschaft_setup_path(assigns(:gemeinschaft_setup))
#   end

#   test "should show gemeinschaft_setup" do
#     get :show, id: @gemeinschaft_setup.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, id: @gemeinschaft_setup.to_param
#     assert_response :success
#   end

#   test "should update gemeinschaft_setup" do
#     put :update, id: @gemeinschaft_setup.to_param, gemeinschaft_setup: @gemeinschaft_setup.attributes
#     assert_redirected_to gemeinschaft_setup_path(assigns(:gemeinschaft_setup))
#   end

#   test "should destroy gemeinschaft_setup" do
#     assert_difference('GemeinschaftSetup.count', -1) do
#       delete :destroy, id: @gemeinschaft_setup.to_param
#     end
#     assert_redirected_to gemeinschaft_setups_path
#   end
  
end
