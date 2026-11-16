module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :set_transaction, only: %i[show update destroy]

      rescue_from Date::Error do
        render json: { errors: [ "Data inválida no filtro" ] }, status: :bad_request
      end

      def index
        return render json: { errors: [ "Tipo inválido" ] }, status: :bad_request if invalid_kind_filter?

        scope = filtered_scope
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = params.fetch(:per_page, 20).to_i.clamp(1, 100)

        response.set_header("X-Total-Count", scope.count.to_s)
        response.set_header("X-Page", page.to_s)
        response.set_header("X-Per-Page", per_page.to_s)

        records = scope.offset((page - 1) * per_page).limit(per_page)
        render json: records.map { |transaction| transaction_json(transaction) }
      end

      def show
        render json: transaction_json(@transaction)
      end

      def create
        transaction = current_user.transactions.create!(transaction_params)
        render json: transaction_json(transaction), status: :created
      end

      def update
        @transaction.update!(transaction_params)
        render json: transaction_json(@transaction)
      end

      def destroy
        @transaction.destroy!
        head :no_content
      end

      private

      def set_transaction
        @transaction = current_user.transactions.find(params[:id])
      end

      def invalid_kind_filter?
        params[:kind].present? && !Transaction.kinds.key?(params[:kind])
      end

      def filtered_scope
        scope = current_user.transactions.includes(:category).order(occurred_on: :desc, id: :desc)
        scope = scope.where("occurred_on >= ?", Date.iso8601(params[:from])) if params[:from].present?
        scope = scope.where("occurred_on <= ?", Date.iso8601(params[:to])) if params[:to].present?
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(kind: params[:kind]) if params[:kind].present?
        scope
      end

      def transaction_params
        params.expect(transaction: %i[category_id kind description amount_cents occurred_on])
      end

      def transaction_json(transaction)
        transaction.as_json(only: %i[id kind description amount_cents occurred_on])
                   .merge("category" => transaction.category.as_json(only: %i[id name kind]))
      end
    end
  end
end
