require 'test_helper'

class GsNodesControllerTest < ActionController::TestCase
  setup do
    @gs_node = gs_nodes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gs_nodes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gs_node" do
    assert_difference('GsNode.count') do
      post :create, gs_node: @gs_node.attributes
    end

    assert_redirected_to gs_node_path(assigns(:gs_node))
  end

  test "should show gs_node" do
    get :show, id: @gs_node.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gs_node.to_param
    assert_response :success
  end

  test "should update gs_node" do
    put :update, id: @gs_node.to_param, gs_node: @gs_node.attributes
    assert_redirected_to gs_node_path(assigns(:gs_node))
  end

  test "should destroy gs_node" do
    assert_difference('GsNode.count', -1) do
      delete :destroy, id: @gs_node.to_param
    end

    assert_redirected_to gs_nodes_path
  end
end
