# PILOT: sends errors and sampled traces to Better Stack via its
# Sentry-compatible ingest, running alongside Honeybadger. Honeybadger remains the alerting
# source of truth. sentry-rails is only loaded when BETTER_STACK_ERRORS_DSN is
# set (config/application.rb, with sentry-sidekiq); unset it to disable entirely.
if Rails.env.production? && ENV["BETTER_STACK_ERRORS_DSN"].present?
  # Mirrors config/initializers/honeybadger.rb so Better Stack's counts are
  # comparable: the same ignored classes, and the same classes collapsed into
  # one error each instead of being dropped.
  ignored_exceptions = %w[
    ActiveRecord::QueryCanceled
    ActiveRecord::RecordNotFound
    Pundit::NotAuthorizedError
    RateLimitChecker::LimitReached
  ]
  message_fingerprints = {
    "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
    "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
    "PG::QueryCanceled" => "pg_query_canceled"
  }

  Sentry.init do |config|
    config.dsn = ENV.fetch("BETTER_STACK_ERRORS_DSN")
    config.enabled_environments = %w[production]
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    config.release = ENV.fetch("HEROKU_SLUG_COMMIT", nil)
    config.breadcrumbs_logger = [:active_support_logger]
    # Sampled request and job traces; Better Stack stores them as spans.
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.05").to_f
    # Like Honeybadger's attempt_threshold: skip job failures that will be retried.
    config.sidekiq.report_after_job_retries = true
    config.excluded_exceptions += ignored_exceptions
    config.inspect_exception_causes_for_exclusion = true

    config.before_send = lambda do |event, hint|
      exception = hint[:exception]
      next if exception.is_a?(SignalException) && exception.message.include?("SIGHUP")

      # Honeybadger matches its error message ("Class: message"), which also
      # catches these classes when they arrive wrapped in another exception.
      error_message = "#{exception.class.name}: #{exception&.message}"
      fingerprint = message_fingerprints.detect { |key, _| error_message.include?(key) }&.last
      event.fingerprint = [fingerprint] if fingerprint
      event
    end
  end
end
