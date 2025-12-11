require "test_helper"

class SuspensionsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get suspensions_edit_url
    assert_response :success
  end

  test "should get update" do
    get suspensions_update_url
    assert_response :success
  end

  test "should get destroy" do
    get suspensions_destroy_url
    assert_response :success
  end
end
