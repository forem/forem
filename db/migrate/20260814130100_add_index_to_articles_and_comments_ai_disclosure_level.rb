class AddIndexToArticlesAndCommentsAiDisclosureLevel < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      # Drop leftover invalid indexes if a previous attempt was interrupted
      if select_value("SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = 'index_articles_on_ai_disclosure_level' AND NOT i.indisvalid")
        execute "SET statement_timeout = 0;"
        execute "DROP INDEX CONCURRENTLY IF EXISTS index_articles_on_ai_disclosure_level;"
      end

      if select_value("SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = 'index_comments_on_ai_disclosure_level' AND NOT i.indisvalid")
        execute "SET statement_timeout = 0;"
        execute "DROP INDEX CONCURRENTLY IF EXISTS index_comments_on_ai_disclosure_level;"
      end

      execute "SET statement_timeout = 0;"
      execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_on_ai_disclosure_level ON articles (ai_disclosure_level);"

      execute "SET statement_timeout = 0;"
      execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS index_comments_on_ai_disclosure_level ON comments (ai_disclosure_level);"
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_articles_on_ai_disclosure_level;"
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_comments_on_ai_disclosure_level;"
    end
  end
end
