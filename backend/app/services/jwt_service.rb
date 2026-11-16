class JwtService
  ALGORITHM = "HS256".freeze
  EXPIRATION = 24.hours

  def self.encode(user_id)
    payload = { sub: user_id.to_s, exp: EXPIRATION.from_now.to_i }
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    decoded, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
    decoded
  rescue JWT::DecodeError
    nil
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
