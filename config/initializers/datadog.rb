Datadog.configure do |c|
  c.env = Rails.env
  c.tracing.enabled = ENV["DD_API_KEY"].present?
  c.tracing.partial_flush.enabled = true

  # Multiple Redis integrations to split Redis usage per-instance to
  # accommodate having a different Redis instance for each use case.
  c.tracing.instrument :redis, service_name: "redis-rpush", describes: { url: ENV.fetch("REDIS_RPUSH_URL", nil) }
  c.tracing.instrument :redis, service_name: "redis-sessions", describes: { url: ENV.fetch("REDIS_SESSIONS_URL", nil) }

  # Sidekiq jobs that spin up thousands of other jobs end up consuming a
  # *lot* of memory on instrumentation alone. This env var allows us to
  # enable it only when needed.
  if ENV["DD_ENABLE_REDIS_SIDEKIQ"] == "true"
    c.tracing.strument :redis, service_name: "redis-sidekiq", describes: { url: ENV.fetch("REDIS_SIDEKIQ_URL", nil) }
  end

  # Generic REDIS_URL comes last, allowing it to overwrite any of the
  # above when multiple Redis use cases are backed by the same Redis URL.
  c.tracing.instrument :redis, service_name: "redis", describes: { url: ENV.fetch("REDIS_URL", nil) }
end

ForemStatsClient = Datadog::Statsd.new
