class AddUserExpiresAtIndexToRecommendedArticlesLists < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      with_statement_timeout_disabled do
        drop_invalid_index_if_exists!("index_recommended_articles_lists_on_user_and_expires")

        add_index :recommended_articles_lists,
                  %i[user_id expires_at],
                  name: "index_recommended_articles_lists_on_user_and_expires",
                  algorithm: :concurrently,
                  if_not_exists: true
      end
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :recommended_articles_lists,
                   name: "index_recommended_articles_lists_on_user_and_expires",
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
