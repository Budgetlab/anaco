require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get error_500" do
    get '/500'
    assert_response :error
    assert response.status == 500
  end

  test "should get error_404" do
    get '/404'
    assert_response :not_found
    assert response.status == 404
  end
  test "should get error_503" do
    get '/503'
    assert response.status == 503
  end
end
