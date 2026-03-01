class RssFeedImport < ApplicationRecord
  belongs_to :rss_feed
  has_many :rss_feed_imported_articles, dependent: :destroy

  enum status: { running: 0, completed: 1, failed: 2 }
end
