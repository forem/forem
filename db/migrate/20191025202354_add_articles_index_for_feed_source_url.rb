class AddArticlesIndexForFeedSourceUrl < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :articles, :feed_source_url, algorithm: :concurrently
  end
end
