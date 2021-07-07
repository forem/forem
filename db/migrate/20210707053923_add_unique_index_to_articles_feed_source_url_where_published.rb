class AddUniqueIndexToArticlesFeedSourceUrlWherePublished < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  
  def up
    if index_exists?(:articles, :feed_source_url, unique: true)
      remove_index :articles, column: :feed_source_url, unique: true, algorithm: :concurrently
    end

    add_index :articles, :feed_source_url, unique: true, where: "published is true", algorithm: :concurrently
  end

  def down
    if index_exists?(:articles, :feed_source_url, unique: true, where: "published is true")
      remove_index :articles, :feed_source_url, unique: true, where: "published is true", algorithm: :concurrently
    end

    add_index :articles, column: :feed_source_url, unique: true, algorithm: :concurrently
  end
end
