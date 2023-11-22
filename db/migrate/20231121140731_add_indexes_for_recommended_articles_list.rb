class AddIndexesForRecommendedArticlesList < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :recommended_articles_lists, :article_ids, using: :gin, algorithm: :concurrently
    add_index :recommended_articles_lists, :placement_area, algorithm: :concurrently
    add_index :recommended_articles_lists, :expires_at, algorithm: :concurrently
  end
end
