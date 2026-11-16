require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  def register(overrides = {})
    post api_v1_auth_register_url,
         params: { name: "Lucas", email: "lucas@email.com", password: "12345678" }.merge(overrides),
         as: :json
  end

  test "register creates a user and returns a token" do
    assert_difference "User.count", 1 do
      register
    end

    assert_response :created
    assert response.parsed_body["token"].present?
    assert_nil response.parsed_body["user"]["password_digest"]
  end

  test "register rejects a short password" do
    assert_no_difference "User.count" do
      register(password: "123")
    end

    assert_response :unprocessable_entity
  end

  test "register rejects a duplicate email" do
    register
    register(name: "Outro")

    assert_response :unprocessable_entity
  end

  test "login returns a token for valid credentials" do
    register
    post api_v1_auth_login_url, params: { email: "LUCAS@email.com", password: "12345678" }, as: :json

    assert_response :success
    assert response.parsed_body["token"].present?
  end

  test "login rejects a wrong password" do
    register
    post api_v1_auth_login_url, params: { email: "lucas@email.com", password: "errada123" }, as: :json

    assert_response :unauthorized
  end

  test "me requires a token" do
    get api_v1_auth_me_url, as: :json

    assert_response :unauthorized
  end

  test "me returns the current user" do
    register
    token = response.parsed_body["token"]

    get api_v1_auth_me_url, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :success
    assert_equal "lucas@email.com", response.parsed_body["user"]["email"]
  end

  test "me rejects an invalid token" do
    get api_v1_auth_me_url, headers: { "Authorization" => "Bearer token-invalido" }, as: :json

    assert_response :unauthorized
  end
end
