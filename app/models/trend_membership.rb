class TrendMembership < ApplicationRecord
  belongs_to :trend, counter_cache: :articles_count
  belongs_to :article

  validates :article_id, uniqueness: { scope: :trend_id }
  validates :distance, presence: true

  after_commit :purge_trend, on: %i[create destroy]
  after_update_commit :purge_trend, if: :saved_change_to_distance?

  private

  def purge_trend
    trend&.purge
  end
end
