class Trend < ApplicationRecord
  has_many :trend_memberships, dependent: :destroy
  has_many :articles, through: :trend_memberships
  belongs_to :tag, optional: true

  before_validation :generate_slug
  after_commit :purge, on: %i[create update destroy]
  after_commit :purge_all, on: %i[create update destroy]

  begin
    has_neighbors :centroid_embedding if column_names.include?("centroid_embedding")
  rescue StandardError
    # db not available yet
  end

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :centroid_embedding, presence: true
  validates :first_observed_at, presence: true
  validates :last_observed_at, presence: true

  scope :hot_and_recent, -> { where("last_observed_at >= ?", 7.days.ago).order(score: :desc, last_observed_at: :desc) }

  def self.purge_all
    EdgeCache::PurgeByKey.call(table_key)
  end

  def purge
    EdgeCache::PurgeByKey.call(record_key)
  end

  def purge_all
    self.class.purge_all
  end

  def top_articles(limit = 3)
    articles.published.order(score: :desc).limit(limit)
  end

  private

  def generate_slug
    return if name.blank?
    return if slug.present? && !will_save_change_to_name?

    base_slug = name.parameterize
    unique_slug = base_slug
    counter = 1

    while Trend.where.not(id: id).exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = unique_slug
  end
end
