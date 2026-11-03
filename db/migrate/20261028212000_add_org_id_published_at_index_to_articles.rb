class AddOrgIdPublishedAtIndexToArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_articles_on_org_id_and_published_at_for_published".freeze

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        invalid_query = "SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid " \
                        "WHERE c.relname = '#{INDEX_NAME}' AND NOT i.indisvalid"
        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};") if conn.exec(invalid_query).ntuples.positive?

        conn.exec(<<~SQL.squish)
          CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME}
          ON articles (organization_id, published_at DESC)
          WHERE (published = true AND organization_id IS NOT NULL);
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

  def with_zero_timeout_connection(&block)
    direct_conn = open_zero_timeout_connection
    return yield_with_zero_timeout_fallback(&block) if direct_conn.nil?

    yield direct_conn
  ensure
    direct_conn&.close
  end

  def open_zero_timeout_connection
    conn_params = connection.raw_connection.conninfo_hash.compact
    conn_params[:host] = conn_params[:host].sub("-pooler", "") if conn_params[:host].present?
    conn = PG::Connection.connect(conn_params)
    conn.exec("SET statement_timeout = 0;")
    conn
  rescue StandardError => e
    conn&.close
    Rails.logger.warn("Direct connection with zero timeout failed (#{e.message}); using standard connection")
    nil
  end

  def yield_with_zero_timeout_fallback
    previous_timeout = connection.select_value("SHOW statement_timeout")
    execute "SET statement_timeout = 0;"
    yield connection.raw_connection
  ensure
    execute "SET statement_timeout = #{connection.quote(previous_timeout)};" if previous_timeout
  end
end
