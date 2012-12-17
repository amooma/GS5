require 'test_helper'

class <%= plural_class_name %>ControllerTest < ActionController::TestCase
  setup do
    <%= item_path :instance_variable => true %> = <%= plural_name %>(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:<%= plural_name %>)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create <%= item_path %>" do
    assert_difference('<%= class_name %>.count') do
      post :create, <%= item_path %>: @<%= item_path %>.attributes
    end

    assert_redirected_to <%= item_path %>_path(assigns(:<%= item_path %>))
  end

  test "should show <%= item_path %>" do
    get :show, id: @<%= item_path %>.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @<%= item_path %>.to_param
    assert_response :success
  end

  test "should update <%= item_path %>" do
    put :update, id: @<%= item_path %>.to_param, <%= item_path %>: @<%= item_path %>.attributes
    assert_redirected_to <%= item_path %>_path(assigns(:<%= item_path %>))
  end

  test "should destroy <%= item_path %>" do
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, id: @<%= item_path %>.to_param
    end

    assert_redirected_to <%= plural_name %>_path
  end
end
