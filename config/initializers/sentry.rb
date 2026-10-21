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

  # sentry-rails only traces top-level render_template.action_view, leaving partial and Jbuilder
  # collection rendering as unattributed "compute" gaps in the trace waterfall.
  action_view_subscriber = Class.new(Sentry::Rails::Tracing::ActionViewSubscriber) do
    const_set(:EVENT_NAMES, %w[
      render_template.action_view
      render_partial.action_view
      render_collection.action_view
    ].freeze)

    def self.subscribe!
      subscribe_to_event(self::EVENT_NAMES) do |event_name, duration, payload|
        record_on_current_span(
          op: self::SPAN_PREFIX + event_name,
          origin: self::SPAN_ORIGIN,
          start_timestamp: payload[Sentry::Rails::Tracing::START_TIMESTAMP_NAME],
          description: payload[:identifier],
          duration: duration,
        ) do |span|
          span.set_data("template.count", payload[:count]) if payload[:count]
          span.set_data("template.cache_hits", payload[:cache_hits]) if payload[:cache_hits]
        end
      end
    end
  end

  # MemoryFirstCache and Flipper read from process-local MemoryStore/LocalStore hundreds of times
  # per request, accounting for ~58% of all spans and truncating complex traces at Sentry's
  # 1,000-span cap before view rendering finishes. Keep distributed cache (RedisCacheStore) spans.
  active_support_subscriber = Class.new(Sentry::Rails::Tracing::ActiveSupportSubscriber) do
    const_set(:READ_EVENT_NAMES, %w[cache_read.active_support cache_read_multi.active_support].freeze)
    const_set(
      :EVENT_NAMES,
      (self::READ_EVENT_NAMES + self::WRITE_EVENT_NAMES + self::REMOVE_EVENT_NAMES + self::FLUSH_EVENT_NAMES).freeze,
    )
    const_set(:IGNORED_STORES, %w[
      ActiveSupport::Cache::MemoryStore
      ActiveSupport::Cache::Strategy::LocalCache::LocalStore
      ActiveSupport::Cache::NullStore
    ].freeze)

    def self.subscribe!
      subscribe_to_event(self::EVENT_NAMES) do |event_name, duration, payload|
        next if self::IGNORED_STORES.include?(payload[:store])

        record_on_current_span(
          op: operation_name(event_name),
          origin: self::SPAN_ORIGIN,
          start_timestamp: payload[Sentry::Rails::Tracing::START_TIMESTAMP_NAME],
          description: payload[:store],
          duration: duration,
        ) do |span|
          keys = Array(payload[:key]).select { |key| Sentry::Utils::EncodingHelper.valid_utf_8?(key) }
          span.set_data("cache.key", keys)
          span.set_data("cache.hit", payload[:hit] == true)
        end
      end
    end

    def self.operation_name(event_name)
      self::READ_EVENT_NAMES.include?(event_name) ? "cache.get" : super
    end
  end

  Sentry.init do |config|
    config.dsn = ENV.fetch("BETTER_STACK_ERRORS_DSN")
    config.enabled_environments = %w[production]
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    config.release = ENV.fetch("HEROKU_SLUG_COMMIT", nil)
    config.breadcrumbs_logger = [:active_support_logger]
    # Sampled request and job traces; Better Stack stores them as spans.
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.05").to_f
    # Trace outgoing HTTP calls via Faraday and Excon alongside Net::HTTP, Redis, and Puma.
    config.enabled_patches += %i[faraday excon]
    config.rails.tracing_subscribers.delete(Sentry::Rails::Tracing::ActionViewSubscriber)
    config.rails.tracing_subscribers.delete(Sentry::Rails::Tracing::ActiveSupportSubscriber)
    config.rails.tracing_subscribers.merge([action_view_subscriber, active_support_subscriber])
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

  # Errors the app reports itself (Rails.error.report) go to Better Stack too. Like Honeybadger's
  # subscriber, only handled ones: unhandled errors already arrive through the middleware and
  # Sidekiq integrations, and Sidekiq's executor would otherwise report every retry.
  require "sentry/rails/error_subscriber"
  handled_errors_subscriber = Class.new(Sentry::Rails::ErrorSubscriber) do
    def report(error, handled:, **)
      super if handled
    end
  end
  Rails.error.subscribe(handled_errors_subscriber.new)
end
