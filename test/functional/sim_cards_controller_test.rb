require 'test_helper'

class SimCardsControllerTest < ActionController::TestCase
  setup do
    @sim_card = sim_cards(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sim_cards)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sim_card" do
    assert_difference('SimCard.count') do
      post :create, sim_card: @sim_card.attributes
    end

    assert_redirected_to sim_card_path(assigns(:sim_card))
  end

  test "should show sim_card" do
    get :show, id: @sim_card.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sim_card.to_param
    assert_response :success
  end

  test "should update sim_card" do
    put :update, id: @sim_card.to_param, sim_card: @sim_card.attributes
    assert_redirected_to sim_card_path(assigns(:sim_card))
  end

  test "should destroy sim_card" do
    assert_difference('SimCard.count', -1) do
      delete :destroy, id: @sim_card.to_param
    end

    assert_redirected_to sim_cards_path
  end
end
