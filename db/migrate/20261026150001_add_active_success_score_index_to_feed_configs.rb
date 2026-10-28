class AddActiveSuccessScoreIndexToFeedConfigs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_feed_configs_on_active_feed_success_score".freeze
  OLD_INDEX_NAME = "index_feed_configs_on_feed_success_score".freeze

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        drop_invalid_index(conn, INDEX_NAME)

        conn.exec(<<~SQL.squish)
          CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME}
          ON feed_configs (feed_success_score DESC)
          WHERE (archived = false);
        SQL

        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{OLD_INDEX_NAME};")
      end
    end
  end

  def down
    safety_assured do
      with_zero_timeout_connection do |conn|
        drop_invalid_index(conn, OLD_INDEX_NAME)

        conn.exec(<<~SQL.squish)
          CREATE INDEX CONCURRENTLY IF NOT EXISTS #{OLD_INDEX_NAME}
          ON feed_configs (feed_success_score);
        SQL

        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};")
      end
    end
  end

  private

  def drop_invalid_index(conn, index_name)
    invalid_query = <<~SQL.squish
      SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
      WHERE c.relname = '#{index_name}' AND NOT i.indisvalid
    SQL
    return unless conn.exec(invalid_query).ntuples.positive?

    conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{index_name};")
  end

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
