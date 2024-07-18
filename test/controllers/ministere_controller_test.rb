require "test_helper"

class MinistereControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ministere_index_url
    assert_response :success
  end

  test "should get show" do
    get ministere_show_url
    assert_response :success
  end
end
