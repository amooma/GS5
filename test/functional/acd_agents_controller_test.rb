require 'test_helper'

class AcdAgentsControllerTest < ActionController::TestCase
  setup do
    @acd_agent = acd_agents(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:acd_agents)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create acd_agent" do
    assert_difference('AcdAgent.count') do
      post :create, acd_agent: @acd_agent.attributes
    end

    assert_redirected_to acd_agent_path(assigns(:acd_agent))
  end

  test "should show acd_agent" do
    get :show, id: @acd_agent.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @acd_agent.to_param
    assert_response :success
  end

  test "should update acd_agent" do
    put :update, id: @acd_agent.to_param, acd_agent: @acd_agent.attributes
    assert_redirected_to acd_agent_path(assigns(:acd_agent))
  end

  test "should destroy acd_agent" do
    assert_difference('AcdAgent.count', -1) do
      delete :destroy, id: @acd_agent.to_param
    end

    assert_redirected_to acd_agents_path
  end
end
