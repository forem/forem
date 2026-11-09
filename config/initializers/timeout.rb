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

    # Send a PostgreSQL CancelRequest before closing the socket so connection poolers
    # (e.g. PgBouncer) and PostgreSQL backends abort the in-flight query immediately,
    # then close the raw connection socket to wake up any blocking C extension call
    # without acquiring the connection's lock (which is held by the request thread).
    def self.cancel_and_close_raw_connection(conn)
      raw_conn = conn.raw_connection
      return unless raw_conn

      begin
        raw_conn.cancel if raw_conn.respond_to?(:cancel)
      rescue StandardError => e
        Rails.logger.warn "Rack::Timeout: failed to cancel database query: #{e.class}: #{e.message}"
      end

      if raw_conn.respond_to?(:close)
        raw_conn.close
      elsif raw_conn.respond_to?(:finish)
        raw_conn.finish
      end
    rescue StandardError => e
      Rails.logger.warn "Rack::Timeout: failed to close raw database connection: #{e.class}: #{e.message}"
    ensure
      conn.instance_variable_set(:@verified, false)
      conn.instance_variable_set(:@last_activity, nil)
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
      RackTimeoutThreadTracker.cancel_and_close_raw_connection(conn) if conn
    end
  end
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
