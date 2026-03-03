class Post < ApplicationRecord
  has_rich_text :body
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :published, -> { where(status: :published).where("published_at <= ?", Time.current) }
  scope :drafts, -> { where(status: :draft) }
  scope :recent, -> { order("published_at DESC NULLS LAST") }

  private

  def generate_slug
    return if title.blank?

    base_slug = title.parameterize
    base_slug = SecureRandom.hex(8) if base_slug.blank?

    candidate = base_slug

    while self.class.exists?(slug: candidate)
      candidate = "#{base_slug}-#{SecureRandom.hex(4)}"
    end

    self.slug = candidate
  end
end
