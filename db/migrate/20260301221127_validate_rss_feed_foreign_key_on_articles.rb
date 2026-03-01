class ValidateRssFeedForeignKeyOnArticles < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :articles, :rss_feeds
  end
end
