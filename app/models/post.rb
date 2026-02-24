class Post < ApplicationRecord
  has_rich_text :body

  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :published, -> { where(status: :published).where("published_at <= ?", Time.current) }
  scope :drafts, -> { where(status: :draft) }
  scope :recent, -> { order(published_at: :desc) }

  private

  def generate_slug
    return if title.blank?

    base_slug = title.parameterize
    self.slug = base_slug

    return unless self.class.exists?(slug: base_slug)

    self.slug = "#{base_slug}-#{SecureRandom.hex(4)}"
  end
end
