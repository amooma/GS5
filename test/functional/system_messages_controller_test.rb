require 'test_helper'

class SystemMessagesControllerTest < ActionController::TestCase
  setup do
    @system_message = system_messages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:system_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create system_message" do
    assert_difference('SystemMessage.count') do
      post :create, system_message: @system_message.attributes
    end

    assert_redirected_to system_message_path(assigns(:system_message))
  end

  test "should show system_message" do
    get :show, id: @system_message.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @system_message.to_param
    assert_response :success
  end

  test "should update system_message" do
    put :update, id: @system_message.to_param, system_message: @system_message.attributes
    assert_redirected_to system_message_path(assigns(:system_message))
  end

  test "should destroy system_message" do
    assert_difference('SystemMessage.count', -1) do
      delete :destroy, id: @system_message.to_param
    end

    assert_redirected_to system_messages_path
  end
end
