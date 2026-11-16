class User < ApplicationRecord
  has_secure_password

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
