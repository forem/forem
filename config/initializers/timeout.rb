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
  end
  Rack::Timeout.prepend(RackTimeoutThreadTracker)

  Rack::Timeout.register_state_change_observer(:clear_db_connections_on_timeout) do |env|
    if env[Rack::Timeout::ENV_INFO_KEY].state == :timed_out
      request_thread = env["rack-timeout.request_thread"]
      if request_thread
        ActiveRecord::Base.connection_handler.connection_pool_list.each do |pool|
          # Safely retrieve the connection cached for the request thread
          tcc = pool.instance_variable_get(:@thread_cached_conns)
          conn = tcc[request_thread] if tcc
          if conn
            begin
              # Close the raw connection socket to wake up any blocking C extension query execution
              # without acquiring the connection's lock (which is held by the request thread).
              raw_conn = conn.raw_connection
              if raw_conn
                if raw_conn.respond_to?(:close)
                  raw_conn.close
                elsif raw_conn.respond_to?(:finish)
                  raw_conn.finish
                end
              end
            rescue StandardError => e
              Rails.logger.warn "Rack::Timeout: failed to close raw database connection: #{e.class}: #{e.message}"
            end
          end
        end
      end
    end
  end
end
