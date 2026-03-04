class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  private

  def generate_slug
    return if name.blank?

    base_slug = name.parameterize
    base_slug = SecureRandom.hex(8) if base_slug.blank?

    candidate = base_slug

    while self.class.exists?(slug: candidate)
      candidate = "#{base_slug}-#{SecureRandom.hex(4)}"
    end

    self.slug = candidate
  end
end
