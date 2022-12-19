Datadog.configure do |c|
  c.env = Rails.env
  c.tracing.enabled = ENV["DD_API_KEY"].present?
  c.tracing.partial_flush.enabled = true
  service_name = ENV.fetch("DD_SERVICE") { "rails-#{Rails.env}" }

  c.tracing.instrument :rails, service_name: service_name
  c.tracing.instrument :active_support, cache_service: "#{service_name}-cache"
  c.tracing.instrument :active_record, service_name: "#{service_name}-db"
  c.tracing.instrument :sidekiq, service_name: "#{service_name}-sidekiq"
  c.tracing.instrument :concurrent_ruby
  c.tracing.instrument :excon, service_name: "#{service_name}-excon"
  c.tracing.instrument :httprb, service_name: "#{service_name}-httprb"
  c.tracing.instrument :http, service_name: "#{service_name}-net_http"
  c.tracing.instrument :faraday, service_name: "#{service_name}-faraday"

  # Multiple Redis integrations to split Redis usage per-instance to
  # accommodate having a different Redis instance for each use case.
  c.tracing.instrument :redis, service_name: "#{service_name}-redis-rpush",
                               describes: { url: ENV.fetch("REDIS_RPUSH_URL", nil) }
  c.tracing.instrument :redis, service_name: "#{service_name}-redis-sessions",
                               describes: { url: ENV.fetch("REDIS_SESSIONS_URL", nil) }
  # Sidekiq jobs that spin up thousands of other jobs end up consuming a
  # *lot* of memory on instrumentation alone. This env var allows us to
  # enable it only when needed.
  if ENV["DD_ENABLE_REDIS_SIDEKIQ"] == "true"
    c.tracing.strument :redis, service_name: "#{service_name}-redis-sidekiq",
                               describes: { url: ENV.fetch("REDIS_SIDEKIQ_URL", nil) }
  end
  # Generic REDIS_URL comes last, allowing it to overwrite any of the
  # above when multiple Redis use cases are backed by the same Redis URL.
  c.tracing.instrument :redis, service_name: "#{service_name}-redis", describes: { url: ENV.fetch("REDIS_URL", nil) }
end

ForemStatsClient = Datadog::Statsd.new
