require 'test_helper'

class SwitchboardEntriesControllerTest < ActionController::TestCase
  setup do
    @switchboard_entry = switchboard_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:switchboard_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create switchboard_entry" do
    assert_difference('SwitchboardEntry.count') do
      post :create, switchboard_entry: @switchboard_entry.attributes
    end

    assert_redirected_to switchboard_entry_path(assigns(:switchboard_entry))
  end

  test "should show switchboard_entry" do
    get :show, id: @switchboard_entry.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @switchboard_entry.to_param
    assert_response :success
  end

  test "should update switchboard_entry" do
    put :update, id: @switchboard_entry.to_param, switchboard_entry: @switchboard_entry.attributes
    assert_redirected_to switchboard_entry_path(assigns(:switchboard_entry))
  end

  test "should destroy switchboard_entry" do
    assert_difference('SwitchboardEntry.count', -1) do
      delete :destroy, id: @switchboard_entry.to_param
    end

    assert_redirected_to switchboard_entries_path
  end
end
