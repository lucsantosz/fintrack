class Category < ApplicationRecord
  belongs_to :user, optional: true

  enum :kind, { income: 0, expense: 1 }, validate: true

  scope :available_to, ->(user) { where(user_id: [ nil, user.id ]) }

  before_validation { self.name = name.to_s.strip }

  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: %i[user_id kind], case_sensitive: false }

  def default?
    user_id.nil?
  end
end
