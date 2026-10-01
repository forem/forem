require "logtail"
require_relative "log_device"

module Betterstack
  # Stands in for ForemStatsClient (a Datadog::Statsd): every call is passed on to `forward_to`
  # unchanged, then written to Better Stack as one structured log event. Only the methods the app
  # calls are implemented. Only loaded when BETTERSTACK_METRICS_SOURCE_TOKEN is set
  # (see config/initializers/datadog.rb).
  class StatsClient
    def initialize(source_token, ingesting_host: nil, forward_to: nil)
      @logger = Logtail::Logger.new(LogDevice.new(source_token, ingesting_host: ingesting_host))
      @forward_to = forward_to
    end

    # Same signatures as Datadog::Statsd, so every existing call site keeps working.
    # rubocop:disable Style/OptionHash
    def increment(stat, opts = {})
      @forward_to&.increment(stat, opts)
      write(:count, stat, opts.fetch(:by, 1), opts)
    end

    def count(stat, count, opts = {})
      @forward_to&.count(stat, count, opts)
      write(:count, stat, count, opts)
    end

    def gauge(stat, value, opts = {})
      @forward_to&.gauge(stat, value, opts)
      write(:gauge, stat, value, opts)
    end

    def event(title, text, opts = {})
      @forward_to&.event(title, text, opts)
      write(:event, title, text, opts)
    end
    # rubocop:enable Style/OptionHash

    private

    # Tags keep Datadog's "key:value" strings.
    def write(type, name, value, opts)
      @logger.info(message: name, metric: { type: type, name: name, value: value, tags: Array(opts[:tags]) })
    end
  end
end
