require "test_helper"

class Api::V1::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok" do
    get api_v1_health_url, as: :json

    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end
end
