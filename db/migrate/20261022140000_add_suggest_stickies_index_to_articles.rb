class AddSuggestStickiesIndexToArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_articles_on_published_at_for_suggest_stickies".freeze

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        invalid_query = <<~SQL.squish
          SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
          WHERE c.relname = '#{INDEX_NAME}' AND NOT i.indisvalid
        SQL
        if conn.exec(invalid_query).ntuples.positive?
          conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};")
        end

        conn.exec(<<~SQL.squish)
          CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME}
          ON articles (published_at)
          WHERE (published = true AND (score > 25 OR comment_score > 15));
        SQL
      end
    end
  end

  def down
    safety_assured do
      with_zero_timeout_connection do |conn|
        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};")
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
      dbname: raw.db
    }
    conn_params[:password] = raw.pass if raw.pass.present?
    conn_params[:sslmode] = "require" if direct_host.present? && !direct_host.start_with?("/")

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
