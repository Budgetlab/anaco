require "test_helper"

class GestionSchemasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gestion_schemas_index_url
    assert_response :success
  end

  test "should get new" do
    get gestion_schemas_new_url
    assert_response :success
  end

  test "should get edit" do
    get gestion_schemas_edit_url
    assert_response :success
  end
end
