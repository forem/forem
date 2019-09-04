if Rails.env.development? && ApplicationConfig["RACK_TIMEOUT_WAIT_TIMEOUT"].nil?
  ApplicationConfig["RACK_TIMEOUT_WAIT_TIMEOUT"] = "100000"
  ApplicationConfig["RACK_TIMEOUT_SERVICE_TIMEOUT"] = "100000"
end

Rack::Timeout.unregister_state_change_observer(:logger) if Rails.env.development?
Rack::Timeout::Logger.disable
