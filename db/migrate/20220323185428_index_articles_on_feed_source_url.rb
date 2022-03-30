class IndexArticlesOnFeedSourceUrl < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  # We already have a unique index scoped to `published = true`, so we need
  # this one to be across all articles.
  INDEX_NAME = :index_articles_on_feed_source_url_unscoped

  def up
    add_index :articles, :feed_source_url,
      name: INDEX_NAME,
      if_not_exists: true,
      algorithm: :concurrently
  end

  def down
    remove_index :articles,
      name: INDEX_NAME,
      if_exists: true,
      algorithm: :concurrently
  end
end
