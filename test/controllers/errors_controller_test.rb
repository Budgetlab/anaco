require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get error_500" do
    get errors_error_500_url
    assert_response :success
  end

  test "should get error_404" do
    get errors_error_404_url
    assert_response :success
  end

  test "should get error_503" do
    get errors_error_503_url
    assert_response :success
  end
end
