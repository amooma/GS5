require 'test_helper'

class RestoreJobsControllerTest < ActionController::TestCase
  setup do
    @restore_job = restore_jobs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:restore_jobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create restore_job" do
    assert_difference('RestoreJob.count') do
      post :create, restore_job: @restore_job.attributes
    end

    assert_redirected_to restore_job_path(assigns(:restore_job))
  end

  test "should show restore_job" do
    get :show, id: @restore_job.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @restore_job.to_param
    assert_response :success
  end

  test "should update restore_job" do
    put :update, id: @restore_job.to_param, restore_job: @restore_job.attributes
    assert_redirected_to restore_job_path(assigns(:restore_job))
  end

  test "should destroy restore_job" do
    assert_difference('RestoreJob.count', -1) do
      delete :destroy, id: @restore_job.to_param
    end

    assert_redirected_to restore_jobs_path
  end
end
