require "ddtrace"
require "datadog/statsd"

Datadog.configure do |c|
  c.tracer env: Rails.env
  c.tracer enabled: Rails.env.production?
  c.tracer partial_flush: true
  c.tracer priority_sampling: true
  c.use :sidekiq
  c.use :redis
  c.use :rails
  c.use :http
end

DataDogStatsClient = Datadog::Statsd.new
