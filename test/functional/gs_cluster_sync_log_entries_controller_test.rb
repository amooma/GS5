require 'test_helper'

class GsClusterSyncLogEntriesControllerTest < ActionController::TestCase
  setup do
    @gs_cluster_sync_log_entry = gs_cluster_sync_log_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gs_cluster_sync_log_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gs_cluster_sync_log_entry" do
    assert_difference('GsClusterSyncLogEntry.count') do
      post :create, gs_cluster_sync_log_entry: @gs_cluster_sync_log_entry.attributes
    end

    assert_redirected_to gs_cluster_sync_log_entry_path(assigns(:gs_cluster_sync_log_entry))
  end

  test "should show gs_cluster_sync_log_entry" do
    get :show, id: @gs_cluster_sync_log_entry.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gs_cluster_sync_log_entry.to_param
    assert_response :success
  end

  test "should update gs_cluster_sync_log_entry" do
    put :update, id: @gs_cluster_sync_log_entry.to_param, gs_cluster_sync_log_entry: @gs_cluster_sync_log_entry.attributes
    assert_redirected_to gs_cluster_sync_log_entry_path(assigns(:gs_cluster_sync_log_entry))
  end

  test "should destroy gs_cluster_sync_log_entry" do
    assert_difference('GsClusterSyncLogEntry.count', -1) do
      delete :destroy, id: @gs_cluster_sync_log_entry.to_param
    end

    assert_redirected_to gs_cluster_sync_log_entries_path
  end
end
