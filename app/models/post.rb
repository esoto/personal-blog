class Post < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy

  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body_markdown, presence: true

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :published, -> { where(status: :published).where("published_at <= ?", Time.current) }
  scope :drafts, -> { where(status: :draft) }
  scope :recent, -> { order("published_at DESC NULLS LAST") }

  def reading_time
    return 1 unless body_markdown.present?

    words = body_markdown.split.size
    minutes = (words / 200.0).ceil
    [ minutes, 1 ].max
  end

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
