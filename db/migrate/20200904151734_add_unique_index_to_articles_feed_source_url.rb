class AddUniqueIndexToArticlesFeedSourceUrl < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    # at this point in time the articles table has a non unique index on feed_source_url,
    # we must replace that with a unique index
    if index_exists?(:articles, :feed_source_url)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    end

    unless index_exists?(:articles, :feed_source_url, unique: true)
      add_index :articles, :feed_source_url, unique: true, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:articles, :feed_source_url, unique: true)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    end

    add_index :articles, :feed_source_url, algorithm: :concurrently
  end
end
