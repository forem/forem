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
      super
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
    end
  end
  Rack::Timeout.prepend(RackTimeoutThreadTracker)

  Rack::Timeout.register_state_change_observer(:clear_db_connections_on_timeout) do |env|
    next unless env[Rack::Timeout::ENV_INFO_KEY].state == :timed_out

    request_thread = env["rack-timeout.request_thread"]
    next unless request_thread

    ActiveRecord::Base.connection_handler.connection_pool_list.each do |pool|
      # Safely retrieve the connection cached for the request thread
      tcc = pool.instance_variable_get(:@thread_cached_conns)
      conn = tcc[request_thread] if tcc
      RackTimeoutThreadTracker.cancel_and_close_raw_connection(conn) if conn
    end
  end
end
