require 'test_helper'

class SimCardProvidersControllerTest < ActionController::TestCase
  setup do
    @sim_card_provider = sim_card_providers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sim_card_providers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sim_card_provider" do
    assert_difference('SimCardProvider.count') do
      post :create, sim_card_provider: @sim_card_provider.attributes
    end

    assert_redirected_to sim_card_provider_path(assigns(:sim_card_provider))
  end

  test "should show sim_card_provider" do
    get :show, id: @sim_card_provider.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sim_card_provider.to_param
    assert_response :success
  end

  test "should update sim_card_provider" do
    put :update, id: @sim_card_provider.to_param, sim_card_provider: @sim_card_provider.attributes
    assert_redirected_to sim_card_provider_path(assigns(:sim_card_provider))
  end

  test "should destroy sim_card_provider" do
    assert_difference('SimCardProvider.count', -1) do
      delete :destroy, id: @sim_card_provider.to_param
    end

    assert_redirected_to sim_card_providers_path
  end
end
