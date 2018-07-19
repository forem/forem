# Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, wait_timeout: 5, service_timeout: ENV["SERVICE_TIMEOUT"].to_i # seconds

Rack::Timeout.unregister_state_change_observer(:logger) if Rails.env.development?
Rack::Timeout::Logger.disable

