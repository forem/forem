# PILOT (2026-07): exports OpenTelemetry traces to Better Stack, running
# alongside ddtrace (Datadog). Head-sampled: set
# OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.1
# alongside the vars below. Remove BETTER_STACK_OTLP_TOKEN to disable entirely.
if ENV["BETTER_STACK_OTLP_TOKEN"].present?
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  # Individual instrumentation gems must be required so they register before `c.use`.
  require "opentelemetry/instrumentation/rails"
  require "opentelemetry/instrumentation/active_record"
  require "opentelemetry/instrumentation/concurrent_ruby"
  require "opentelemetry/instrumentation/excon"
  require "opentelemetry/instrumentation/faraday"
  require "opentelemetry/instrumentation/http"
  require "opentelemetry/instrumentation/net/http"
  require "opentelemetry/instrumentation/pg"
  require "opentelemetry/instrumentation/redis"
  require "opentelemetry/instrumentation/sidekiq"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "forem")

    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: "https://#{ENV.fetch('BETTER_STACK_OTLP_HOST')}/v1/traces",
          headers: { "Authorization" => "Bearer #{ENV.fetch('BETTER_STACK_OTLP_TOKEN')}" },
          compression: "gzip",
        ),
      ),
    )

    c.use "OpenTelemetry::Instrumentation::Rails"
    c.use "OpenTelemetry::Instrumentation::ActiveRecord"
    c.use "OpenTelemetry::Instrumentation::ConcurrentRuby"
    c.use "OpenTelemetry::Instrumentation::Excon"
    c.use "OpenTelemetry::Instrumentation::Faraday"
    c.use "OpenTelemetry::Instrumentation::HTTP"
    c.use "OpenTelemetry::Instrumentation::Net::HTTP"
    c.use "OpenTelemetry::Instrumentation::PG" # sanitized SQL by default
    c.use "OpenTelemetry::Instrumentation::Redis"
    c.use "OpenTelemetry::Instrumentation::Sidekiq", {
      span_naming: :job_class,   # spans named after the job class, not the queue
      propagation_style: :link   # each job gets its own trace, linked to the enqueuer
    }
  end

  # Heroku sends SIGTERM on dyno cycling; BatchSpanProcessor buffers in
  # memory, so flush explicitly or the last batch of spans is silently lost.
  at_exit { OpenTelemetry.tracer_provider.shutdown(timeout: 5) }
end
