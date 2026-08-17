class AddIndexToArticlesAndCommentsAiDisclosureLevel < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Drop leftover invalid indexes if a previous attempt was interrupted
    if connection.select_value("SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = 'index_articles_on_ai_disclosure_level' AND NOT i.indisvalid")
      connection.execute "SET statement_timeout = 0;"
      connection.execute "DROP INDEX CONCURRENTLY IF EXISTS index_articles_on_ai_disclosure_level;"
    end

    if connection.select_value("SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = 'index_comments_on_ai_disclosure_level' AND NOT i.indisvalid")
      connection.execute "SET statement_timeout = 0;"
      connection.execute "DROP INDEX CONCURRENTLY IF EXISTS index_comments_on_ai_disclosure_level;"
    end

    connection.execute "SET statement_timeout = 0;"
    add_index :articles, :ai_disclosure_level, algorithm: :concurrently unless index_exists?(:articles, :ai_disclosure_level)

    connection.execute "SET statement_timeout = 0;"
    add_index :comments, :ai_disclosure_level, algorithm: :concurrently unless index_exists?(:comments, :ai_disclosure_level)
  end

  def down
    remove_index :articles, :ai_disclosure_level, algorithm: :concurrently if index_exists?(:articles, :ai_disclosure_level)
    remove_index :comments, :ai_disclosure_level, algorithm: :concurrently if index_exists?(:comments, :ai_disclosure_level)
  end
end
