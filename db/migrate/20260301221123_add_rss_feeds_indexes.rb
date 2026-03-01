class AddRssFeedsIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :rss_feeds, %i[user_id feed_url], unique: true, algorithm: :concurrently
    add_index :rss_feeds, :status, algorithm: :concurrently
    add_index :rss_feeds, :last_fetched_at, algorithm: :concurrently
    add_index :rss_feed_items, %i[rss_feed_id item_url], unique: true, algorithm: :concurrently
    add_index :rss_feed_items, :status, algorithm: :concurrently
    add_index :rss_feed_items, %i[rss_feed_id status], algorithm: :concurrently
  end
end
