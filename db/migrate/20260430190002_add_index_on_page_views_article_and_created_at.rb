class AddIndexOnPageViewsArticleAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded page_views aggregation in AnalyticsService,
  # which queries by article_id and groups by created_at date.
  def change
    add_index :page_views,
              %i[article_id created_at],
              name: "index_page_views_on_article_id_and_created_at",
              algorithm: :concurrently
  end
end
