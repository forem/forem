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

stats_client = Datadog::Statsd.new
# Also send metrics to Better Stack when BETTERSTACK_METRICS_SOURCE_TOKEN is set.
if Rails.env.production? && ENV["BETTERSTACK_METRICS_SOURCE_TOKEN"].present?
  require Rails.root.join("lib/betterstack/stats_client")
  stats_client = Betterstack::StatsClient.new(
    ENV.fetch("BETTERSTACK_METRICS_SOURCE_TOKEN"),
    ingesting_host: ENV["BETTERSTACK_METRICS_INGESTING_HOST"].presence,
    forward_to: stats_client,
  )
end
ForemStatsClient = stats_client # rubocop:disable Naming/ConstantName
