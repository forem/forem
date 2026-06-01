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
          # Safely retrieve and disconnect the connection cached for the request thread
          tcc = pool.instance_variable_get(:@thread_cached_conns)
          conn = tcc[request_thread] if tcc
          if conn
            begin
              conn.disconnect!
            rescue StandardError => e
              Rails.logger.warn "Rack::Timeout: failed to disconnect timed out connection: #{e.class}: #{e.message}"
              conn.discard! if conn.respond_to?(:discard!)
            end
          end
          # Release the connection back to the pool
          begin
            pool.release_connection(request_thread)
          rescue StandardError => e
            Rails.logger.warn "Rack::Timeout: failed to release timed out connection: #{e.class}: #{e.message}"
          end
        end
      end
    end
  end
end
