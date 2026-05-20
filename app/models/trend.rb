class Trend < ApplicationRecord
  has_many :trend_memberships, dependent: :destroy
  has_many :articles, through: :trend_memberships

  has_neighbors :centroid_embedding

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :centroid_embedding, presence: true

  before_validation :generate_slug, on: :create

  scope :hot_and_recent, -> { order(score: :desc, last_observed_at: :desc) }

  private

  def generate_slug
    return if name.blank?

    base_slug = name.parameterize
    unique_slug = base_slug
    counter = 1

    while Trend.exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = unique_slug
  end
end
