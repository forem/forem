class AddUserIdNotifiedAtIndexToNotifications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_notifications_on_user_id_and_notified_at".freeze

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
          ON notifications (user_id, notified_at);
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

    direct_conn = begin
      PG::Connection.connect(conn_params)
    rescue PG::Error
      Rails.logger.warn("Direct connection unavailable; using standard connection")
      nil
    end

    if direct_conn
      begin
        direct_conn.exec("SET statement_timeout = 0;")
        yield direct_conn
      ensure
        direct_conn.close
      end
    else
      previous_timeout = connection.select_value("SHOW statement_timeout")
      begin
        execute "SET statement_timeout = 0;"
        yield raw
      ensure
        execute "SET statement_timeout = #{connection.quote(previous_timeout)};"
      end
    end
  end
end
