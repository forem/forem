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
    # Records the current request thread and monotonic start time in the Rack env
    # and thread-local storage for timeout tracking, restoring previous values afterward.
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
    # Instead, taint the adapter so it disconnects cleanly on the owning thread during
    # transaction rollback or pool checkin once the request thread finishes unwinding.
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

    singleton_class.alias_method :cancel_and_close_raw_connection, :cancel_and_taint_connection

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
    # Clears the Rack::Timeout taint flag when the adapter disconnects.
    def disconnect!
      @rack_timeout_tainted = false
      super
    end

    # Clears the Rack::Timeout taint flag when the adapter reconnects.
    def reconnect!(...)
      @rack_timeout_tainted = false
      super
    end

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
#
# In addition, when a request times out inside `ActiveRecord::Base.transaction`
# (`@rack_timeout_tainted == true`), `TransactionManager#within_new_transaction`
# rescues `Rack::Timeout::RequestTimeoutException` and calls `rollback_transaction`.
# Default `PostgreSQLAdapter#exec_rollback_db_transaction` calls `@raw_connection.block`
# (without a timeout) and sends `ROLLBACK`, which can hang the unwinding request
# thread if `PQcancel` did not abort the in-flight query or the socket is unresponsive.
# Closing `@raw_connection` on the owning request thread instead aborts the server-side
# transaction immediately without blocking.
module PostgreSQLAdapterClosedConnectionReconnect
  # Reports tainted connections as inactive so SavepointTransaction#rollback skips
  # issuing queries over a timed-out socket and verify! triggers a full reconnect.
  def active?
    return false if @rack_timeout_tainted

    super
  end

  # Clears the Rack::Timeout taint flag when the PostgreSQL adapter disconnects.
  def disconnect!
    @rack_timeout_tainted = false
    super
  end

  private

  # Closes the raw PG::Connection on the owning request thread instead of blocking
  # on `@raw_connection.block` and `ROLLBACK` when unwinding a timed-out transaction.
  def exec_rollback_db_transaction
    return close_tainted_raw_connection if @rack_timeout_tainted

    super
  end

  # Closes the raw PG::Connection on the owning request thread instead of blocking
  # on `@raw_connection.block` and `ROLLBACK AND CHAIN` when a timed-out transaction restarts.
  def exec_restart_db_transaction
    return close_tainted_raw_connection if @rack_timeout_tainted

    super
  end

  # Closes the raw PG::Connection on the owning request thread instead of issuing
  # `ROLLBACK TO SAVEPOINT` over a timed-out connection.
  def exec_rollback_to_savepoint(_name = nil)
    return close_tainted_raw_connection if @rack_timeout_tainted

    super
  end

  # Closes and clears `@raw_connection` on the owning thread without raising.
  def close_tainted_raw_connection
    begin
      @raw_connection&.close
    rescue StandardError
      nil
    end
    @raw_connection = nil
    @verified = false
    @last_activity = nil
  end

  # Returns false when `@raw_connection` is nil or already closed so
  # `AbstractAdapter#with_raw_connection` proceeds to `retryable_connection_error?`
  # and `reconnect!` instead of raising a nested `PG::ConnectionBad` from `#transaction_status`.
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
