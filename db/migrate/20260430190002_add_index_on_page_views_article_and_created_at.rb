class AddIndexOnPageViewsArticleAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded page_views aggregation in AnalyticsService,
  # which queries by article_id and groups by created_at date.
  def up
    safety_assured do
      db_user = connection.query_value("SELECT current_user")
      begin
        execute "ALTER ROLE #{db_user} SET statement_timeout = 0;"
        execute "SET statement_timeout = 0;"

        remove_index :page_views, name: "index_page_views_on_article_id_and_created_at", if_exists: true, algorithm: :concurrently

        add_index :page_views,
                  %i[article_id created_at],
                  name: "index_page_views_on_article_id_and_created_at",
                  algorithm: :concurrently
      ensure
        execute "ALTER ROLE #{db_user} RESET statement_timeout;"
      end
    end
  end

  def down
    remove_index :page_views, name: "index_page_views_on_article_id_and_created_at", if_exists: true, algorithm: :concurrently
  end
end
