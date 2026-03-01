class RssFeedItem < ApplicationRecord
  belongs_to :rss_feed
  belongs_to :article, optional: true

  enum status: { pending: 0, imported: 1, skipped: 2, error: 3 }

  validates :item_url, presence: true, uniqueness: { scope: :rss_feed_id }

  scope :recent, -> { order(detected_at: :desc) }
end
