class AddUserExpiresAtIndexToRecommendedArticlesLists < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      # Drop leftover invalid indexes if a previous attempt was interrupted
      invalid_query = <<~SQL.squish
        SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
        WHERE c.relname = 'index_recommended_articles_lists_on_user_and_expires' AND NOT i.indisvalid
      SQL
      if select_value(invalid_query)
        execute "SET statement_timeout = 0;"
        execute "DROP INDEX CONCURRENTLY IF EXISTS index_recommended_articles_lists_on_user_and_expires;"
      end

      execute "SET statement_timeout = 0;"
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_recommended_articles_lists_on_user_and_expires
        ON recommended_articles_lists (user_id, expires_at);
      SQL
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_recommended_articles_lists_on_user_and_expires;"
    end
  end
end
