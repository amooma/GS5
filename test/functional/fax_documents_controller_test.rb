require 'test_helper'

class FaxDocumentsControllerTest < ActionController::TestCase
  setup do
    @fax_document = fax_documents(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fax_documents)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fax_document" do
    assert_difference('FaxDocument.count') do
      post :create, fax_document: @fax_document.attributes
    end

    assert_redirected_to fax_document_path(assigns(:fax_document))
  end

  test "should show fax_document" do
    get :show, id: @fax_document.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fax_document.to_param
    assert_response :success
  end

  test "should update fax_document" do
    put :update, id: @fax_document.to_param, fax_document: @fax_document.attributes
    assert_redirected_to fax_document_path(assigns(:fax_document))
  end

  test "should destroy fax_document" do
    assert_difference('FaxDocument.count', -1) do
      delete :destroy, id: @fax_document.to_param
    end

    assert_redirected_to fax_documents_path
  end
end
