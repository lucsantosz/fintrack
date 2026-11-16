module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    return if current_user

    render json: { errors: [ "Não autenticado" ] }, status: :unauthorized
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = find_user_from_token
  end

  def find_user_from_token
    token = request.headers["Authorization"].to_s[/\ABearer (.+)\z/, 1]
    return nil if token.blank?

    payload = JwtService.decode(token)
    payload && User.find_by(id: payload["sub"])
  end
end
