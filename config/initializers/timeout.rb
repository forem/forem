if Rails.env.development? && ENV["RACK_TIMEOUT_WAIT_TIMEOUT"].nil?
  ENV["RACK_TIMEOUT_WAIT_TIMEOUT"] = "100000"
  ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"] = "100000"
end

Rack::Timeout.unregister_state_change_observer(:logger) if Rails.env.development?
Rack::Timeout::Logger.disable

if defined?(Rack::Timeout) && defined?(ActiveRecord::Base)
  Rack::Timeout.register_state_change_observer(:clear_db_connections_on_timeout) do |env|
    if env[Rack::Timeout::ENV_INFO_KEY].state == :timed_out
      ActiveRecord::Base.connection_pool.active_connection?&.disconnect!
      ActiveRecord::Base.clear_active_connections!
    end
  end
end
