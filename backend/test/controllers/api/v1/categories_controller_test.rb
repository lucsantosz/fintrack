require "test_helper"

class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Ana", email: "ana@email.com", password: "12345678")
    @other = User.create!(name: "Beto", email: "beto@email.com", password: "12345678")
    @default = Category.create!(name: "Alimentação", kind: :expense)
    @own = Category.create!(user: @user, name: "Pets", kind: :expense)
    @others = Category.create!(user: @other, name: "Hobbies", kind: :expense)
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{JwtService.encode(user.id)}" }
  end

  test "requires authentication" do
    get api_v1_categories_url, as: :json

    assert_response :unauthorized
  end

  test "index lists default and own categories only" do
    get api_v1_categories_url, headers: auth_headers(@user), as: :json

    names = response.parsed_body.map { |category| category["name"] }
    assert_includes names, "Alimentação"
    assert_includes names, "Pets"
    assert_not_includes names, "Hobbies"
  end

  test "create adds a category for the current user" do
    assert_difference "@user.categories.count", 1 do
      post api_v1_categories_url,
           params: { category: { name: "Academia", kind: "expense" } },
           headers: auth_headers(@user), as: :json
    end

    assert_response :created
  end

  test "create rejects a blank name" do
    post api_v1_categories_url,
         params: { category: { name: "", kind: "expense" } },
         headers: auth_headers(@user), as: :json

    assert_response :unprocessable_entity
  end

  test "create rejects an invalid kind" do
    post api_v1_categories_url,
         params: { category: { name: "Teste", kind: "outro" } },
         headers: auth_headers(@user), as: :json

    assert_response :unprocessable_entity
  end

  test "update changes an own category" do
    patch api_v1_category_url(@own),
          params: { category: { name: "Animais" } },
          headers: auth_headers(@user), as: :json

    assert_response :success
    assert_equal "Animais", @own.reload.name
  end

  test "update of a default category is forbidden" do
    patch api_v1_category_url(@default),
          params: { category: { name: "Comida" } },
          headers: auth_headers(@user), as: :json

    assert_response :forbidden
  end

  test "another user's category is not found" do
    patch api_v1_category_url(@others),
          params: { category: { name: "Invadido" } },
          headers: auth_headers(@user), as: :json

    assert_response :not_found
    assert_equal "Hobbies", @others.reload.name
  end

  test "destroy removes an own category" do
    assert_difference "Category.count", -1 do
      delete api_v1_category_url(@own), headers: auth_headers(@user), as: :json
    end

    assert_response :no_content
  end
end
