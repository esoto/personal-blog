class Comment < ApplicationRecord
  belongs_to :post

  enum :status, { pending: 0, approved: 1, spam: 2 }

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :author_name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :body, presence: true, length: { maximum: 5000 }

  scope :recent, -> { order(created_at: :desc) }
end
