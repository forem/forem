class AddIndexOnPageViewsArticleAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded page_views aggregation in AnalyticsService,
  # which queries by article_id and groups by created_at date.
  def up
    safety_assured do
      # Drop in case a previous deploy timed out and left an invalid index
      remove_index :page_views, name: "index_page_views_on_article_id_and_created_at", if_exists: true, algorithm: :concurrently

      say "WARNING: Concurrent index creation on page_views skipped due to PgBouncer timeout limitations."
      say "Please run the following manually or via a DataUpdateWorker:"
      say "CREATE INDEX CONCURRENTLY index_page_views_on_article_id_and_created_at ON page_views (article_id, created_at);"
    end
  end

  def down
    remove_index :page_views, name: "index_page_views_on_article_id_and_created_at", if_exists: true, algorithm: :concurrently
  end
end
