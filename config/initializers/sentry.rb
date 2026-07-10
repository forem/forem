# Exception class names mirrored from config/initializers/honeybadger.rb
# (its ignore list plus its fingerprint-grouped classes) so pilot error
# volume on Better Stack matches what Honeybadger actually counts.
SENTRY_PILOT_IGNORED_EXCEPTIONS = %w[
  ActiveRecord::QueryCanceled
  ActiveRecord::RecordNotFound
  Pundit::NotAuthorizedError
  RateLimitChecker::LimitReached
  Rack::Timeout::RequestTimeoutException
  Rack::Timeout::RequestTimeoutError
  PG::QueryCanceled
].freeze

# PILOT (2026-07): sends errors to Better Stack via its Sentry-compatible
# ingest, running alongside Honeybadger. Honeybadger remains the alerting
# source of truth. Remove BETTER_STACK_ERRORS_DSN to disable entirely.
if ENV["BETTER_STACK_ERRORS_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["BETTER_STACK_ERRORS_DSN"]
    config.enabled_environments = %w[production]
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    config.release = ENV.fetch("HEROKU_SLUG_COMMIT", nil)
    config.breadcrumbs_logger = [:active_support_logger]
    # Tracing goes through OpenTelemetry (config/initializers/opentelemetry.rb), not Sentry.
    config.traces_sample_rate = 0.0
    config.excluded_exceptions += SENTRY_PILOT_IGNORED_EXCEPTIONS
    config.inspect_exception_causes_for_exclusion = true
  end
end
