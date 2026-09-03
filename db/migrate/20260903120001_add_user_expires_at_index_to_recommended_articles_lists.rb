class AddUserExpiresAtIndexToRecommendedArticlesLists < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        invalid_query = <<~SQL.squish
          SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
          WHERE c.relname = 'index_recommended_articles_lists_on_user_and_expires' AND NOT i.indisvalid
        SQL
        if conn.exec(invalid_query).ntuples.positive?
          conn.exec("DROP INDEX CONCURRENTLY IF EXISTS index_recommended_articles_lists_on_user_and_expires;")
        end

        conn.exec(<<~SQL.squish)
          CREATE INDEX CONCURRENTLY IF NOT EXISTS index_recommended_articles_lists_on_user_and_expires
          ON recommended_articles_lists (user_id, expires_at);
        SQL
      end
    end
  end

  def down
    safety_assured do
      with_zero_timeout_connection do |conn|
        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS index_recommended_articles_lists_on_user_and_expires;")
      end
    end
  end

  private

  def with_zero_timeout_connection
    raw = connection.raw_connection
    direct_host = raw.host.to_s.sub("-pooler", "")
    conn_params = {
      host: direct_host,
      port: raw.port,
      user: raw.user,
      dbname: raw.db,
      options: "-c statement_timeout=0"
    }
    conn_params[:password] = raw.pass if raw.pass.present?
    conn_params[:sslmode] = "require" if raw.ssl_in_use?

    direct_conn = PG::Connection.connect(conn_params)
    begin
      direct_conn.exec("SET statement_timeout = 0;")
      yield direct_conn
    ensure
      direct_conn.close
    end
  rescue StandardError => e
    Rails.logger.warn("Direct connection with zero timeout failed (#{e.message}); using standard connection")
    execute "SET statement_timeout = 0;"
    yield connection.raw_connection
  end
end
