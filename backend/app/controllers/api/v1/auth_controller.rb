module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[register login]

      def register
        user = User.create!(register_params)
        render json: auth_payload(user), status: :created
      end

      def login
        user = User.find_by(email: params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password].to_s)
          render json: auth_payload(user)
        else
          render json: { errors: [ "E-mail ou senha inválidos" ] }, status: :unauthorized
        end
      end

      def me
        render json: { user: user_json(current_user) }
      end

      private

      def register_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def auth_payload(user)
        { token: JwtService.encode(user.id), user: user_json(user) }
      end

      def user_json(user)
        user.as_json(only: %i[id name email])
      end
    end
  end
end
