require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Ana", email: "ana@email.com", password: "12345678")
    @other = User.create!(name: "Beto", email: "beto@email.com", password: "12345678")
    @food = Category.create!(name: "Alimentação", kind: :expense)
    @salary = Category.create!(name: "Salário", kind: :income)
    @others_category = Category.create!(user: @other, name: "Hobbies", kind: :expense)
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{JwtService.encode(user.id)}" }
  end

  def make(attrs = {})
    Transaction.create!({ user: @user, category: @food, kind: :expense, description: "Mercado",
                          amount_cents: 12_550, occurred_on: Date.new(2026, 11, 10) }.merge(attrs))
  end

  def post_transaction(attrs = {})
    post api_v1_transactions_url,
         params: { transaction: { category_id: @food.id, kind: "expense", description: "Mercado",
                                  amount_cents: 12_550, occurred_on: "2026-11-10" }.merge(attrs) },
         headers: auth_headers(@user), as: :json
  end

  test "requires authentication" do
    get api_v1_transactions_url, as: :json

    assert_response :unauthorized
  end

  test "create adds a transaction stored in cents" do
    assert_difference "@user.transactions.count", 1 do
      post_transaction
    end

    assert_response :created
    assert_equal 12_550, response.parsed_body["amount_cents"]
    assert_equal "Alimentação", response.parsed_body["category"]["name"]
  end

  test "create rejects a zero amount" do
    post_transaction(amount_cents: 0)

    assert_response :unprocessable_entity
  end

  test "create rejects another user's category" do
    post_transaction(category_id: @others_category.id)

    assert_response :unprocessable_entity
  end

  test "create rejects a kind that does not match the category" do
    post_transaction(kind: "income")

    assert_response :unprocessable_entity
  end

  test "create rejects an absurd date" do
    post_transaction(occurred_on: "0021-01-01")

    assert_response :unprocessable_entity
  end

  test "index lists only the current user's transactions" do
    make(description: "Minha")
    make(user: @other, category: @others_category, description: "Dele")

    get api_v1_transactions_url, headers: auth_headers(@user), as: :json

    assert_equal [ "Minha" ], response.parsed_body.map { |transaction| transaction["description"] }
  end

  test "index filters by period" do
    make(description: "Antiga", occurred_on: Date.new(2026, 10, 5))
    make(description: "Recente", occurred_on: Date.new(2026, 11, 5))

    get api_v1_transactions_url(from: "2026-11-01", to: "2026-11-30"), headers: auth_headers(@user), as: :json

    assert_equal [ "Recente" ], response.parsed_body.map { |transaction| transaction["description"] }
  end

  test "index filters by kind and category" do
    make(description: "Despesa")
    make(category: @salary, kind: :income, description: "Receita")

    get api_v1_transactions_url(kind: "income"), headers: auth_headers(@user), as: :json
    assert_equal [ "Receita" ], response.parsed_body.map { |transaction| transaction["description"] }

    get api_v1_transactions_url(category_id: @food.id), headers: auth_headers(@user), as: :json
    assert_equal [ "Despesa" ], response.parsed_body.map { |transaction| transaction["description"] }
  end

  test "index paginates and reports the total" do
    3.times { |i| make(description: "Item #{i}") }

    get api_v1_transactions_url(page: 2, per_page: 2), headers: auth_headers(@user), as: :json

    assert_equal 1, response.parsed_body.size
    assert_equal "3", response.headers["X-Total-Count"]
  end

  test "index rejects an invalid date filter" do
    get api_v1_transactions_url(from: "2026-13-45"), headers: auth_headers(@user), as: :json

    assert_response :bad_request
  end

  test "show hides another user's transaction" do
    transaction = make(user: @other, category: @others_category)

    get api_v1_transaction_url(transaction), headers: auth_headers(@user), as: :json

    assert_response :not_found
  end

  test "update changes the description" do
    transaction = make

    patch api_v1_transaction_url(transaction),
          params: { transaction: { description: "Feira" } },
          headers: auth_headers(@user), as: :json

    assert_response :success
    assert_equal "Feira", transaction.reload.description
  end

  test "update does not touch another user's transaction" do
    transaction = make(user: @other, category: @others_category)

    patch api_v1_transaction_url(transaction),
          params: { transaction: { description: "Invadida" } },
          headers: auth_headers(@user), as: :json

    assert_response :not_found
    assert_equal "Mercado", transaction.reload.description
  end

  test "destroy removes the transaction" do
    transaction = make

    assert_difference "Transaction.count", -1 do
      delete api_v1_transaction_url(transaction), headers: auth_headers(@user), as: :json
    end

    assert_response :no_content
  end

  test "a category with transactions cannot be deleted" do
    own = Category.create!(user: @user, name: "Pets", kind: :expense)
    make(category: own)

    assert_no_difference "Category.count" do
      delete api_v1_category_url(own), headers: auth_headers(@user), as: :json
    end

    assert_response :unprocessable_entity
  end
end
