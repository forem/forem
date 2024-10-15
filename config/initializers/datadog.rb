Datadog.configure do |c|
  c.env = Rails.env
  c.tracing.enabled = ENV["DD_API_KEY"].present?
  c.tracing.partial_flush.enabled = true
  c.diagnostics.startup_logs.enabled = Rails.env.production?
  c.tracing.log_injection = ENV["TRACING_LOG_INJECTION"] == "yes"
  service_name = ENV.fetch("DD_SERVICE") { "rails-#{Rails.env}" }

  c.tracing.instrument :rails, service_name: service_name
  c.tracing.instrument :active_support, cache_service: "#{service_name}-cache"
  c.tracing.instrument :active_record, service_name: "#{service_name}-db"
  c.tracing.instrument :sidekiq, service_name: "#{service_name}-sidekiq"
  c.tracing.instrument :concurrent_ruby

  # All HTTP clients roll up to one
  unified_service_name = "#{service_name}-http_clients"
  c.tracing.instrument :excon, service_name: unified_service_name
  c.tracing.instrument :httprb, service_name: unified_service_name
  c.tracing.instrument :http, service_name: unified_service_name
  c.tracing.instrument :faraday, service_name: unified_service_name

  # Instrument all Redis calls (excluding cache) under "#{service_name}-redis"
  c.tracing.instrument :redis, service_name: "#{service_name}-redis"
end

ForemStatsClient = Datadog::Statsd.new