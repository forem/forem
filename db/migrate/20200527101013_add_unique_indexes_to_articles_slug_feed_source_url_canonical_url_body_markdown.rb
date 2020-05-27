class AddUniqueIndexesToArticlesSlugFeedSourceUrlCanonicalUrlBodyMarkdown < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    if index_exists?(:articles, :feed_source_url)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    end

    add_index :articles, %i[slug user_id], unique: true, algorithm: :concurrently
    add_index :articles, :feed_source_url, unique: true, algorithm: :concurrently
    add_index :articles, :canonical_url, unique: true, algorithm: :concurrently
    add_index :articles, %i[body_markdown user_id title], unique: true, algorithm: :concurrently
  end

  def down
    remove_index :articles, column: %i[slug user_id], algorithm: :concurrently
    remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    remove_index :articles, column: :canonical_url, algorithm: :concurrently
    remove_index :articles, column: %i[body_markdown user_id title], algorithm: :concurrently
  end
end
