class ReadOnlyDatabaseService
  # Environment variable for read-only database URL
  READ_ONLY_DATABASE_URL = ENV.fetch("READ_ONLY_DATABASE_URL", nil)

  # Cache for the read-only connection pool
  @@read_only_connection_pool = nil

  class << self
    def available?
      READ_ONLY_DATABASE_URL.present?
    end

    def connection_info
      return unless available?

      uri = URI.parse(READ_ONLY_DATABASE_URL)
      {
        host: uri.host,
        port: uri.port || 5432,
        database: uri.path[1..-1],
        username: uri.user
      }
    end

    def connection_pool
      return unless available?

      # Create connection pool if it doesn't exist
      if @@read_only_connection_pool.nil?
        @@read_only_connection_pool = create_read_only_connection_pool
      end

      @@read_only_connection_pool
    end

    def with_connection
      if available?
        Rails.logger.debug("Using read-only database for user query execution")
        connection_pool.with_connection do |conn|
          original_settings = fetch_session_settings(conn)
          begin
            yield conn
          ensure
            restore_session_settings(conn, original_settings)
          end
        end
      else
        Rails.logger.debug("Read-only database not configured, using main database for user query execution")
        # Fall back to main database if read-only is not configured
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          original_settings = fetch_session_settings(conn)
          begin
            yield conn
          ensure
            restore_session_settings(conn, original_settings)
          end
        end
      end
    end

    def reset_connection_pool!
      return unless @@read_only_connection_pool

      @@read_only_connection_pool.disconnect!
      @@read_only_connection_pool = nil
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

    def create_read_only_connection_pool
      # Parse the read-only database URL
      uri = URI.parse(READ_ONLY_DATABASE_URL)

      # Extract connection parameters
      config = {
        adapter: "postgresql",
        host: uri.host,
        port: uri.port || 5432,
        database: uri.path[1..-1], # Remove leading slash
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

      # Create a new connection pool for read-only database
      ActiveRecord::ConnectionAdapters::ConnectionPool.new(
        ActiveRecord::Base.configurations.resolve(config)
      )
    end

    def fetch_session_settings(connection)
      {
        statement_timeout: connection.execute("SHOW statement_timeout").first["statement_timeout"],
        lock_timeout: connection.execute("SHOW lock_timeout").first["lock_timeout"],
        idle_in_transaction_session_timeout: connection.execute("SHOW idle_in_transaction_session_timeout").first["idle_in_transaction_session_timeout"],
        row_security: connection.execute("SHOW row_security").first["row_security"]
      }
    rescue => e
      Rails.logger.warn("Failed to fetch session settings: #{e.message}")
      nil
    end

    def restore_session_settings(connection, original_settings)
      return unless original_settings

      connection.execute(
        "SET statement_timeout = '#{original_settings[:statement_timeout]}'; " \
        "SET lock_timeout = '#{original_settings[:lock_timeout]}'; " \
        "SET idle_in_transaction_session_timeout = '#{original_settings[:idle_in_transaction_session_timeout]}'; " \
        "SET row_security = '#{original_settings[:row_security]}';"
      )
    rescue => e
      Rails.logger.warn("Failed to restore session settings: #{e.message}")
    end
  end
end
