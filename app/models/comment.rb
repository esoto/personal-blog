class Comment < ApplicationRecord
  belongs_to :post

  enum :status, { pending: 0, approved: 1, spam: 2 }

  validates :author_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :body, presence: true

  scope :approved, -> { where(status: :approved) }
  scope :pending, -> { where(status: :pending) }
  scope :spam, -> { where(status: :spam) }
  scope :recent, -> { order(created_at: :desc) }
end
