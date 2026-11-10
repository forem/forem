if Rails.env.development? && ENV["RACK_TIMEOUT_WAIT_TIMEOUT"].nil?
  ENV["RACK_TIMEOUT_WAIT_TIMEOUT"] = "100000"
  ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"] = "100000"
end

if defined?(Rack::Timeout)
  Rack::Timeout.unregister_state_change_observer(:logger) if Rails.env.development?
  Rack::Timeout::Logger.disable
end

if defined?(Rack::Timeout) && defined?(ActiveRecord::Base)
  # Prepend a tracker to record the request thread so the background monitor thread can clean it up
  module RackTimeoutThreadTracker
    def call(env)
      env["rack-timeout.request_thread"] = Thread.current
      previous_env = Thread.current[:rack_timeout_env]
      previous_started_at = Thread.current[:rack_timeout_started_at]
      Thread.current[:rack_timeout_env] = env
      Thread.current[:rack_timeout_started_at] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      super
    ensure
      Thread.current[:rack_timeout_env] = previous_env
      Thread.current[:rack_timeout_started_at] = previous_started_at
    end

    # Returns the remaining Rack::Timeout budget (in seconds) for the current
    # request thread, or nil when not running inside a timed Rack request.
    def self.remaining_timeout
      env = Thread.current[:rack_timeout_env]
      started_at = Thread.current[:rack_timeout_started_at]
      return unless env && started_at

      info = env[Rack::Timeout::ENV_INFO_KEY]
      timeout = info&.timeout
      return unless timeout.is_a?(Numeric) && timeout.positive?

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      [timeout - elapsed, 0.0].max
    end

    # Sends a thread-safe PostgreSQL CancelRequest (PQcancel) to abort any in-flight
    # query on the timed-out request thread without acquiring the adapter lock or
    # closing the PG::Connection cross-thread. Closing raw_conn from the monitor thread
    # races with the still-executing request thread (causing IOError / NilClass errors)
    # and leaves a finished PG::Connection assigned to @raw_connection in the pool.
    # Instead, taint the adapter so it disconnects cleanly on checkin once the request
    # thread finishes unwinding.
    def self.cancel_and_taint_connection(conn)
      conn.instance_variable_set(:@rack_timeout_tainted, true)
      conn.instance_variable_set(:@verified, false)
      conn.instance_variable_set(:@last_activity, nil)

      raw_conn = conn.instance_variable_get(:@raw_connection)
      return unless raw_conn
      return if raw_conn.respond_to?(:finished?) && raw_conn.finished?

      raw_conn.cancel if raw_conn.respond_to?(:cancel)
    rescue StandardError => e
      Rails.logger.warn "Rack::Timeout: failed to cancel database query: #{e.class}: #{e.message}"
    end

    # Locates the ActiveRecord connection currently checked out by request_thread
    # across Rails 7 (@thread_cached_conns) and Rails 8 (@leases / @connections).
    def self.connection_for_thread(pool, request_thread)
      tcc = pool.instance_variable_get(:@thread_cached_conns)
      return tcc[request_thread] if tcc

      leases = pool.instance_variable_get(:@leases)
      if leases
        lease = leases[request_thread]
        return lease.connection if lease.respond_to?(:connection) && lease.connection
      end

      conns = pool.instance_variable_get(:@connections)
      conns&.detect { |c| c.owner == request_thread }
    end
  end
  Rack::Timeout.prepend(RackTimeoutThreadTracker)

  Rack::Timeout.register_state_change_observer(:clear_db_connections_on_timeout) do |env|
    next unless env[Rack::Timeout::ENV_INFO_KEY].state == :timed_out

    request_thread = env["rack-timeout.request_thread"]
    next unless request_thread

    ActiveRecord::Base.connection_handler.connection_pool_list.each do |pool|
      conn = RackTimeoutThreadTracker.connection_for_thread(pool, request_thread)
      RackTimeoutThreadTracker.cancel_and_taint_connection(conn) if conn
    end
  end

  module RackTimeoutTaintedConnectionCleanup
    private

    # Disconnects adapters tainted by a Rack::Timeout (or left with a closed raw
    # driver connection) on the owning thread when checked back into the pool,
    # ensuring @raw_connection is nil so the next checkout cleanly reconnects.
    def disconnect_tainted_rack_timeout_connection
      raw_closed = @raw_connection.respond_to?(:finished?) && @raw_connection.finished?
      return unless @rack_timeout_tainted || raw_closed

      @rack_timeout_tainted = false
      disconnect!
    rescue StandardError => e
      @raw_connection = nil
      @verified = false
      @last_activity = nil
      Rails.logger.warn "Rack::Timeout: failed to disconnect tainted database connection: #{e.class}: #{e.message}"
    end
  end

  ActiveSupport.on_load(:active_record) do
    ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(RackTimeoutTaintedConnectionCleanup)
    ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback(
      :checkin,
      :after,
      :disconnect_tainted_rack_timeout_connection,
    )
  end
end

# Rails 8.0's PostgreSQLAdapter#retryable_query_error? calls
# `@raw_connection&.transaction_status` inside `with_raw_connection`'s rescue block
# before reaching `retryable_connection_error?` -> `reconnect!`. If `@raw_connection`
# has been closed (`finished? == true`), `#transaction_status` itself raises an
# unhandled `PG::ConnectionBad: connection is closed`, aborting auto-reconnect and
# leaving the closed connection in the pool for subsequent read queries to hit.
module PostgreSQLAdapterClosedConnectionReconnect
  private

  def retryable_query_error?(exception)
    return false if @raw_connection.nil? || @raw_connection.finished?

    super
  rescue PG::Error
    false
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  prepend(PostgreSQLAdapterClosedConnectionReconnect)
end

# Rails 8.0's ActiveRecord::Associations::Association#find_target executes cached
# association SELECT queries through StatementCache#execute without passing
# `allow_retry: true` (unlike Core#find / Core#find_by). Because StatementCache
# only ever executes read-only SELECT queries via find_by_sql, default
# `allow_retry: true` so pooled connections closed upstream by PgBouncer/Postgres
# within `verify_timeout` automatically reconnect and retry.
if defined?(ActiveRecord::StatementCache)
  module ActiveRecordStatementCacheRetryable
    # Executes the cached read-only SELECT statement with allow_retry: true by default.
    def execute(params, connection, allow_retry: true, async: false, &block)
      super
    end
  end
  ActiveRecord::StatementCache.prepend(ActiveRecordStatementCacheRetryable)
end
