require 'test_helper'

class ConferenceInviteesControllerTest < ActionController::TestCase
  
  setup do
    @conference_invitee = Factory.create(:conference_invitee)
  end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:conference_invitees)
#   end
# 
#   test "should get new" do
#     get :new
#     assert_response :success
#   end
# 
#   test "should create conference_invitee" do
#     assert_difference('ConferenceInvitee.count') do
#       post :create, conference_invitee: @conference_invitee.attributes
#     end
#     assert_redirected_to conference_invitee_path(assigns(:conference_invitee))
#   end
# 
#   test "should show conference_invitee" do
#     get :show, id: @conference_invitee.to_param
#     assert_response :success
#   end
# 
#   test "should get edit" do
#     get :edit, id: @conference_invitee.to_param
#     assert_response :success
#   end
# 
#   test "should update conference_invitee" do
#     put :update, id: @conference_invitee.to_param, conference_invitee: @conference_invitee.attributes
#     assert_redirected_to conference_invitee_path(assigns(:conference_invitee))
#   end
# 
#   test "should destroy conference_invitee" do
#     assert_difference('ConferenceInvitee.count', -1) do
#       delete :destroy, id: @conference_invitee.to_param
#     end
#     assert_redirected_to conference_invitees_path
#   end
  
end
