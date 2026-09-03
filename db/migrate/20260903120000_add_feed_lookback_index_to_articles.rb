class AddFeedLookbackIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      with_statement_timeout_disabled do
        drop_invalid_index_if_exists!("index_articles_on_published_at_and_score")

        add_index :articles,
                  %i[published_at score],
                  name: "index_articles_on_published_at_and_score",
                  where: "published = true",
                  order: { published_at: :desc },
                  algorithm: :concurrently,
                  if_not_exists: true
      end
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :articles,
                   name: "index_articles_on_published_at_and_score",
                   if_exists: true,
                   algorithm: :concurrently
    end
  end

  private

  def with_statement_timeout_disabled
    db_user = connection.query_value("SELECT current_user")
    begin
      execute "ALTER ROLE \"#{db_user}\" SET statement_timeout = 0;"
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("Could not alter role statement_timeout: #{e.message}")
    end
    execute "SET statement_timeout = 0;"
    yield
  ensure
    begin
      execute "ALTER ROLE \"#{db_user}\" RESET statement_timeout;"
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("Could not reset role statement_timeout: #{e.message}")
    end
  end

  def drop_invalid_index_if_exists!(index_name)
    query = <<~SQL.squish
      SELECT 1 FROM pg_index i
      JOIN pg_class c ON c.oid = i.indexrelid
      WHERE c.relname = '#{index_name}' AND NOT i.indisvalid
    SQL
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{index_name};" if select_value(query)
  end
end
