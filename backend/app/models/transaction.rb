class Transaction < ApplicationRecord
  MAX_AMOUNT_CENTS = 1_000_000_000

  belongs_to :user
  belongs_to :category

  enum :kind, { income: 0, expense: 1 }, validate: true

  before_validation { self.description = description.to_s.strip }

  validates :description, presence: true, length: { maximum: 120 }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_AMOUNT_CENTS }
  validates :occurred_on, presence: true
  validate :occurred_on_must_be_reasonable
  validate :category_must_be_available_to_user
  validate :kind_must_match_category

  private

  def occurred_on_must_be_reasonable
    return if occurred_on.blank?

    errors.add(:occurred_on, "must be between 2000 and 2100") unless occurred_on.year.between?(2000, 2100)
  end

  def category_must_be_available_to_user
    return if category.blank? || user.blank?

    errors.add(:category, "is not available") unless category.user_id.nil? || category.user_id == user_id
  end

  def kind_must_match_category
    return if category.blank? || kind.blank?

    errors.add(:kind, "must match the category kind") unless kind == category.kind
  end
end
