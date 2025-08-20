# Development Performance Optimizations
# This file disables heavy monitoring and analytics services in development
# to improve performance and reduce overhead

if Rails.env.development?
  # Disable Honeybadger in development unless explicitly enabled
  unless ENV["HONEYBADGER_ENABLED"] == "true"
    Honeybadger.configure do |config|
      config.api_key = nil
      config.send_data_at_exit = false
      # Disable all notifications
      config.before_notify do |notice|
        notice.parameters = {}
        notice.cgi_data = {}
        notice.session_data = {}
        notice.backtrace = []
        notice.error_message = "Honeybadger disabled in development"
      end
    end
  end

  # Disable Honeycomb in development unless explicitly enabled
  unless ENV["HONEYCOMB_ENABLED"] == "true"
    Honeycomb.configure do |config|
      config.write_key = nil
      config.client = Libhoney::NullClient.new
    end
  end

  # Disable Datadog tracing in development unless explicitly enabled
  unless ENV["DD_ENABLED"] == "true"
    Datadog.configure do |c|
      c.tracing.enabled = false
      c.diagnostics.startup_logs.enabled = false
    end
  end

  # Disable Ahoy tracking in development unless explicitly enabled
  unless ENV["AHOY_ENABLED"] == "true"
    Ahoy.api = false
    Ahoy.server_side_visits = false
    Ahoy.mask_ips = true
    Ahoy.cookies = :none
    Ahoy.geocode = false
  end

  # Reduce logging verbosity for better performance
  Rails.logger.level = Logger::INFO

  # Disable SQL logging in development for cleaner output
  ActiveRecord::Base.logger = nil if ENV["SQL_LOGGING"] != "true"

  puts "🚀 Development performance optimizations enabled!"
  puts "   - Honeybadger disabled (set HONEYBADGER_ENABLED=true to enable)"
  puts "   - Honeycomb disabled (set HONEYCOMB_ENABLED=true to enable)"
  puts "   - Datadog disabled (set DD_ENABLED=true to enable)"
  puts "   - Ahoy tracking disabled (set AHOY_ENABLED=true to enable)"
  puts "   - Bullet disabled (set BULLET_ENABLED=true to enable)"
  puts "   - SQL logging disabled (set SQL_LOGGING=true to enable)"
end
