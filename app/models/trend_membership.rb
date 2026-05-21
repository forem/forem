class TrendMembership < ApplicationRecord
  belongs_to :trend, counter_cache: :articles_count
  belongs_to :article

  validates :article_id, uniqueness: { scope: :trend_id }
  validates :distance, presence: true

  after_commit :purge_trend, on: %i[create update destroy]

  private

  def purge_trend
    trend&.purge
    trend&.purge_all
  end
end
