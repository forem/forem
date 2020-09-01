class AddUniqueIndexToArticlesSlugAndFeedSourceUrl < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  # Ifs/unless are added for idempotency
  def up
    unless index_exists?(:articles, %i[slug user_id], unique: true)
      add_index :articles, %i[slug user_id], unique: true, algorithm: :concurrently
    end

    # At this point in time `articles` has a non unique index on `feed_source_url`.
    # We need to replace that regular index with a unique index
    if index_exists?(:articles, :feed_source_url)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    end

    unless index_exists?(:articles, :feed_source_url, unique: true)
      add_index :articles, :feed_source_url, unique: true, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:articles, %i[slug user_id], unique: true)
      remove_index :articles, column: %i[slug user_id], algorithm: :concurrently
    end

    if index_exists?(:articles, :feed_source_url, unique: true)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently

      # we re-add the non unique index
      add_index :articles, :feed_source_url, algorithm: :concurrently
    end
  end
end
