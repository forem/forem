class ReadOnlyDatabaseService
  class << self
    def read_only_database_url
      ENV.fetch("READ_ONLY_DATABASE_URL", nil).presence
    end

    def available?
      read_only_database_url.present?
    end

    def connection_info
      return unless available?

      uri = URI.parse(read_only_database_url)
      {
        host: uri.host,
        port: uri.port || 5432,
        database: uri.path[1..],
        username: uri.user
      }
    end

    def connection_pool
      return unless available?

      @connection_pool ||= create_read_only_connection_pool
    end

    def with_connection(&block)
      if available?
        begin
          Rails.logger.debug("Using read-only database for user query execution")
          connection_pool.with_connection do |conn|
            original_settings = fetch_session_settings(conn)
            begin
              yield conn
            ensure
              restore_session_settings(conn, original_settings)
            end
          end
        rescue PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished, ActiveRecord::DatabaseConnectionError => e
          Rails.logger.error(
            "Read-only database connection failed (#{e.class}: #{e.message}), falling back to main database",
          )
          with_main_database_connection(&block)
        end
      else
        Rails.logger.debug("Read-only database not configured, using main database for user query execution")
        with_main_database_connection(&block)
      end
    end

    def reset_connection_pool!
      return unless @connection_pool

      @connection_pool.disconnect!
      @connection_pool = nil
    end

    def health_check
      return { status: "not_configured", message: "Read-only database not configured" } unless available?

      begin
        with_connection do |conn|
          conn.execute("SELECT 1 as health_check")
          { status: "healthy", message: "Read-only database connection successful" }
        end
      rescue StandardError => e
        { status: "unhealthy", message: "Read-only database connection failed: #{e.message}" }
      end
    end

    private

    def with_main_database_connection
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        original_settings = fetch_session_settings(conn)
        begin
          yield conn
        ensure
          restore_session_settings(conn, original_settings)
        end
      end
    end

    def create_read_only_connection_pool
      uri = URI.parse(read_only_database_url)

      config = {
        adapter: "postgresql",
        host: uri.host,
        port: uri.port || 5432,
        database: uri.path[1..],
        username: uri.user,
        password: uri.password,
        encoding: "unicode",
        pool: ENV.fetch("READ_ONLY_DATABASE_POOL_SIZE", 5).to_i,
        connect_timeout: 6,
        checkout_timeout: 10,
        idle_timeout: 60,
        reaping_frequency: 40,
        variables: {
          statement_timeout: ENV.fetch("READ_ONLY_STATEMENT_TIMEOUT", 30_000).to_i
        }
      }

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(
        ActiveRecord::Base.configurations.resolve(config),
      )
    end

    def fetch_session_settings(connection)
      idle_timeout = connection.execute(
        "SHOW idle_in_transaction_session_timeout",
      ).first["idle_in_transaction_session_timeout"]

      {
        statement_timeout: connection.execute("SHOW statement_timeout").first["statement_timeout"],
        lock_timeout: connection.execute("SHOW lock_timeout").first["lock_timeout"],
        idle_in_transaction_session_timeout: idle_timeout,
        row_security: connection.execute("SHOW row_security").first["row_security"]
      }
    rescue StandardError => e
      Rails.logger.warn("Failed to fetch session settings: #{e.message}")
      nil
    end

    def restore_session_settings(connection, original_settings)
      return unless original_settings

      connection.execute(
        "SET statement_timeout = '#{original_settings[:statement_timeout]}'; " \
        "SET lock_timeout = '#{original_settings[:lock_timeout]}'; " \
        "SET idle_in_transaction_session_timeout = '#{original_settings[:idle_in_transaction_session_timeout]}'; " \
        "SET row_security = '#{original_settings[:row_security]}';",
      )
    rescue StandardError => e
      Rails.logger.warn("Failed to restore session settings: #{e.message}")
    end
  end
end
