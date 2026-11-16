module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_own_category, only: %i[update destroy]

      def index
        categories = Category.available_to(current_user).order(:kind, :name)
        render json: categories.map { |category| category_json(category) }
      end

      def create
        category = current_user.categories.create!(category_params)
        render json: category_json(category), status: :created
      end

      def update
        @category.update!(params.expect(category: [ :name ]))
        render json: category_json(@category)
      end

      def destroy
        if @category.destroy
          head :no_content
        else
          render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_own_category
        category = Category.available_to(current_user).find(params[:id])

        if category.default?
          render json: { errors: [ "Categorias padrão não podem ser alteradas" ] }, status: :forbidden
        else
          @category = category
        end
      end

      def category_params
        params.expect(category: %i[name kind])
      end

      def category_json(category)
        category.as_json(only: %i[id name kind]).merge("default" => category.default?)
      end
    end
  end
end
