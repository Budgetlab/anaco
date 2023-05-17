require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get error_500" do
    get '/anaco/500'
    assert_response :error
    assert response.status == 500
  end

  test "should get error_404" do
    get '/anaco/404'
    assert_response :not_found
    assert response.status == 404
  end
  test "should get error_503" do
    get '/anaco/503'
    assert response.status == 503
  end
end
