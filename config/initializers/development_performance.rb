# Development Performance Optimizations
# This file disables heavy monitoring and analytics services in development
# to improve performance and reduce overhead

if Rails.env.development?
  # Disable Honeybadger in development unless explicitly enabled
  if !(ENV["HONEYBADGER_ENABLED"] == "true") && defined?(Honeybadger)
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
  if !(ENV["HONEYCOMB_ENABLED"] == "true") && defined?(Honeycomb)
    Honeycomb.configure do |config|
      config.write_key = nil
      config.client = Libhoney::NullClient.new
    end
  end

  # Disable Datadog tracing in development unless explicitly enabled
  if !(ENV["DD_ENABLED"] == "true") && defined?(Datadog)
    Datadog.configure do |c|
      c.tracing.enabled = false
      c.diagnostics.startup_logs.enabled = false
    end
  end

  # Disable Ahoy tracking in development unless explicitly enabled
  if !(ENV["AHOY_ENABLED"] == "true") && defined?(Ahoy)
    begin
      Ahoy.api = false
      Ahoy.server_side_visits = false
      Ahoy.mask_ips = true
      Ahoy.cookies = :none
      Ahoy.geocode = false
    rescue StandardError => e
      # Log the error but don't crash the application
      Rails.logger.warn "Failed to configure Ahoy in development: #{e.message}" if defined?(Rails.logger)
    end
  end

  # Reduce logging verbosity for better performance
  Rails.logger.level = Logger::INFO if Rails.logger

  # Disable SQL logging in development for cleaner output
  # Only disable if explicitly requested and not in a rake task context
  if ENV["SQL_LOGGING"] != "true" && !defined?(Rake)
    ActiveRecord::Base.logger = nil
  end

  puts "🚀 Development performance optimizations enabled!"
  puts "   - Honeybadger disabled (set HONEYBADGER_ENABLED=true to enable)"
  puts "   - Honeycomb disabled (set HONEYCOMB_ENABLED=true to enable)"
  puts "   - Datadog disabled (set DD_ENABLED=true to enable)"
  puts "   - Ahoy tracking disabled (set AHOY_ENABLED=true to enable)"
  puts "   - Bullet disabled (set BULLET_ENABLED=true to enable)"
  puts "   - SQL logging disabled (set SQL_LOGGING=true to enable)"
end
