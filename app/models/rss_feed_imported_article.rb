class RssFeedImportedArticle < ApplicationRecord
  belongs_to :rss_feed_import
  belongs_to :article, optional: true

  enum status: { imported: 0, skipped: 1, failed: 2 }
end
