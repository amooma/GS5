require 'test_helper'

class SipDomainsControllerTest < ActionController::TestCase
  setup do
    @sip_domain = Factory.create(:sip_domain)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sip_domains)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sip_domain" do
    assert_difference('SipDomain.count') do
      post :create, sip_domain: Factory.build(:sip_domain).attributes
    end

    assert_redirected_to sip_domain_path(assigns(:sip_domain))
  end

  test "should show sip_domain" do
    get :show, id: @sip_domain.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sip_domain.to_param
    assert_response :success
  end

  test "should update sip_domain" do
    put :update, id: @sip_domain.to_param, sip_domain: @sip_domain.attributes
    assert_redirected_to sip_domain_path(assigns(:sip_domain))
  end

  test "should destroy sip_domain" do
    assert_difference('SipDomain.count', -1) do
      delete :destroy, id: @sip_domain.to_param
    end

    assert_redirected_to sip_domains_path
  end
end
