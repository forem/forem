Rack::Timeout.service_timeout = ENV["SERVICE_TIMEOUT"].to_i # seconds
Rack::Timeout.wait_timeout = 5
Rack::Timeout.unregister_state_change_observer(:logger) if Rails.env.development?
