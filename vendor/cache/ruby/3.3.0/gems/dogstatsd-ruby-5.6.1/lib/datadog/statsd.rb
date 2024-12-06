# frozen_string_literal: true
require 'socket'

require_relative 'statsd/version'
require_relative 'statsd/telemetry'
require_relative 'statsd/udp_connection'
require_relative 'statsd/uds_connection'
require_relative 'statsd/connection_cfg'
require_relative 'statsd/message_buffer'
require_relative 'statsd/serialization'
require_relative 'statsd/sender'
require_relative 'statsd/single_thread_sender'
require_relative 'statsd/forwarder'
require_relative 'statsd/timer'

# = Datadog::Statsd: A DogStatsd client (https://www.datadoghq.com)
#
# @example Set up a global Statsd client for a server on localhost:8125
#   require 'datadog/statsd'
#   $statsd = Datadog::Statsd.new 'localhost', 8125
# @example Send some stats
#   $statsd.increment 'page.views'
#   $statsd.timing 'page.load', 320
#   $statsd.gauge 'users.online', 100
# @example Use {#time} to time the execution of a block
#   $statsd.time('account.activate') { @account.activate! }
# @example Create a namespaced statsd client and increment 'account.activate'
#   statsd = Datadog::Statsd.new 'localhost', 8125, :namespace => 'account'
#   statsd.increment 'activate'
# @example Create a statsd client with global tags
#   statsd = Datadog::Statsd.new 'localhost', 8125, tags: 'tag1:true'
module Datadog
  class Statsd
    class Error < StandardError
    end

    OK       = 0
    WARNING  = 1
    CRITICAL = 2
    UNKNOWN  = 3

    UDP_DEFAULT_BUFFER_SIZE = 1_432
    UDS_DEFAULT_BUFFER_SIZE = 8_192
    DEFAULT_BUFFER_POOL_SIZE = Float::INFINITY

    UDP_DEFAULT_SENDER_QUEUE_SIZE = 2048
    UDS_DEFAULT_SENDER_QUEUE_SIZE = 512

    MAX_EVENT_SIZE = 8 * 1_024

    # minimum flush interval for the telemetry in seconds
    DEFAULT_TELEMETRY_FLUSH_INTERVAL = 10

    COUNTER_TYPE = 'c'
    GAUGE_TYPE = 'g'
    HISTOGRAM_TYPE = 'h'
    DISTRIBUTION_TYPE = 'd'
    TIMING_TYPE = 'ms'
    SET_TYPE = 's'

    # A namespace to prepend to all statsd calls. Defaults to no namespace.
    attr_reader :namespace

    # Global tags to be added to every statsd call. Defaults to no tags.
    def tags
      serializer.global_tags
    end

    # Default sample rate
    attr_reader :sample_rate

    # @param [String] host your statsd host
    # @param [Integer] port your statsd port
    # @option [String] namespace set a namespace to be prepended to every metric name
    # @option [Array<String>|Hash] tags tags to be added to every metric
    # @option [Logger] logger for debugging
    # @option [Integer] buffer_max_payload_size max bytes to buffer
    # @option [Integer] buffer_max_pool_size max messages to buffer
    # @option [Integer] sender_queue_size size of the sender queue in number of buffers
    # @option [Numeric] buffer_flush_interval interval in second to flush buffer
    # @option [String] socket_path unix socket path
    # @option [Float] default sample rate if not overridden
    # @option [Boolean] single_thread flushes the metrics on the main thread instead of in a companion thread
    # @option [Boolean] delay_serialization delays stat serialization
    def initialize(
      host = nil,
      port = nil,
      socket_path: nil,

      namespace: nil,
      tags: nil,
      sample_rate: nil,

      buffer_max_payload_size: nil,
      buffer_max_pool_size: nil,
      buffer_overflowing_stategy: :drop,
      buffer_flush_interval: nil,

      sender_queue_size: nil,

      logger: nil,

      single_thread: false,
      delay_serialization: false,

      telemetry_enable: true,
      telemetry_flush_interval: DEFAULT_TELEMETRY_FLUSH_INTERVAL
    )
      unless tags.nil? || tags.is_a?(Array) || tags.is_a?(Hash)
        raise ArgumentError, 'tags must be an array of string tags or a Hash'
      end

      @namespace = namespace
      @prefix = @namespace ? "#{@namespace}.".freeze : nil
      @serializer = Serialization::Serializer.new(prefix: @prefix, global_tags: tags)
      @sample_rate = sample_rate
      @delay_serialization = delay_serialization

      @forwarder = Forwarder.new(
        connection_cfg: ConnectionCfg.new(
          host: host,
          port: port,
          socket_path: socket_path,
        ),

        global_tags: tags,
        logger: logger,

        single_thread: single_thread,

        buffer_max_payload_size: buffer_max_payload_size,
        buffer_max_pool_size: buffer_max_pool_size,
        buffer_overflowing_stategy: buffer_overflowing_stategy,
        buffer_flush_interval: buffer_flush_interval,

        sender_queue_size: sender_queue_size,

        telemetry_flush_interval: telemetry_enable ? telemetry_flush_interval : nil,
        serializer: serializer
      )
    end

    # yield a new instance to a block and close it when done
    # for short-term use-cases that don't want to close the socket manually
    # TODO: replace with ... once we are on ruby 2.7
    def self.open(*args, **kwargs)
      instance = new(*args, **kwargs)

      yield instance
    ensure
      instance.close if instance
    end

    # Sends an increment (count = 1) for the given stat to the statsd server.
    #
    # @param [String] stat stat name
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @option opts [Numeric] :by increment value, default 1
    # @see #count
    def increment(stat, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      incr_value = opts.fetch(:by, 1)
      count(stat, incr_value, opts)
    end

    # Sends a decrement (count = -1) for the given stat to the statsd server.
    #
    # @param [String] stat stat name
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @option opts [Numeric] :by decrement value, default 1
    # @see #count
    def decrement(stat, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      decr_value = - opts.fetch(:by, 1)
      count(stat, decr_value, opts)
    end

    # Sends an arbitrary count for the given stat to the statsd server.
    #
    # @param [String] stat stat name
    # @param [Integer] count count
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    def count(stat, count, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      send_stats(stat, count, COUNTER_TYPE, opts)
    end

    # Sends an arbitrary gauge value for the given stat to the statsd server.
    #
    # This is useful for recording things like available disk space,
    # memory usage, and the like, which have different semantics than
    # counters.
    #
    # @param [String] stat stat name.
    # @param [Numeric] value gauge value.
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @example Report the current user count:
    #   $statsd.gauge('user.count', User.count)
    def gauge(stat, value, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      send_stats(stat, value, GAUGE_TYPE, opts)
    end

    # Sends a value to be tracked as a histogram to the statsd server.
    #
    # @param [String] stat stat name.
    # @param [Numeric] value histogram value.
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @example Report the current user count:
    #   $statsd.histogram('user.count', User.count)
    def histogram(stat, value, opts = EMPTY_OPTIONS)
      send_stats(stat, value, HISTOGRAM_TYPE, opts)
    end

    # Sends a value to be tracked as a distribution to the statsd server.
    #
    # @param [String] stat stat name.
    # @param [Numeric] value distribution value.
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @example Report the current user count:
    #   $statsd.distribution('user.count', User.count)
    def distribution(stat, value, opts = EMPTY_OPTIONS)
      send_stats(stat, value, DISTRIBUTION_TYPE, opts)
    end

    # Reports execution time of the provided block as a distribution.
    #
    # If the block fails, the stat is still reported, then the error
    # is reraised
    #
    # @param [String] stat stat name.
    # @param [Numeric] value distribution value.
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Array<String>] :tags An array of tags
    # @example Report the time (in ms) taken to activate an account
    #   $statsd.distribution_time('account.activate') { @account.activate! }
    def distribution_time(stat, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      start = now
      yield
    ensure
      distribution(stat, ((now - start) * 1000).round, opts)
    end

    # Sends a timing (in ms) for the given stat to the statsd server. The
    # sample_rate determines what percentage of the time this report is sent. The
    # statsd server then uses the sample_rate to correctly track the average
    # timing for the stat.
    #
    # @param [String] stat stat name
    # @param [Integer] ms timing in milliseconds
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    def timing(stat, ms, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      send_stats(stat, ms, TIMING_TYPE, opts)
    end

    # Reports execution time of the provided block using {#timing}.
    #
    # If the block fails, the stat is still reported, then the error
    # is reraised
    #
    # @param [String] stat stat name
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @yield The operation to be timed
    # @see #timing
    # @example Report the time (in ms) taken to activate an account
    #   $statsd.time('account.activate') { @account.activate! }
    def time(stat, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      start = now
      yield
    ensure
      timing(stat, ((now - start) * 1000).round, opts)
    end

    # Sends a value to be tracked as a set to the statsd server.
    #
    # @param [String] stat stat name.
    # @param [Numeric] value set value.
    # @param [Hash] opts the options to create the metric with
    # @option opts [Numeric] :sample_rate sample rate, 1 for always
    # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
    # @option opts [Array<String>] :tags An array of tags
    # @example Record a unique visitory by id:
    #   $statsd.set('visitors.uniques', User.id)
    def set(stat, value, opts = EMPTY_OPTIONS)
      opts = { sample_rate: opts } if opts.is_a?(Numeric)
      send_stats(stat, value, SET_TYPE, opts)
    end

    # This method allows you to send custom service check statuses.
    #
    # @param [String] name Service check name
    # @param [String] status Service check status.
    # @param [Hash] opts the additional data about the service check
      # @option opts [Integer, String, nil] :timestamp (nil) Assign a timestamp to the service check. Default is now when none
      # @option opts [String, nil] :hostname (nil) Assign a hostname to the service check.
      # @option opts [Array<String>, nil] :tags (nil) An array of tags
      # @option opts [String, nil] :message (nil) A message to associate with this service check status
    # @example Report a critical service check status
    #   $statsd.service_check('my.service.check', Statsd::CRITICAL, :tags=>['urgent'])
    def service_check(name, status, opts = EMPTY_OPTIONS)
      telemetry.sent(service_checks: 1) if telemetry

      forwarder.send_message(serializer.to_service_check(name, status, opts))
    end

    # This end point allows you to post events to the stream. You can tag them, set priority and even aggregate them with other events.
    #
    # Aggregation in the stream is made on hostname/event_type/source_type/aggregation_key.
    # If there's no event type, for example, then that won't matter;
    # it will be grouped with other events that don't have an event type.
    #
    # @param [String] title Event title
    # @param [String] text Event text. Supports newlines (+\n+)
    # @param [Hash] opts the additional data about the event
    # @option opts [Integer, String, nil] :date_happened (nil) Assign a timestamp to the event. Default is now when none
    # @option opts [String, nil] :hostname (nil) Assign a hostname to the event.
    # @option opts [String, nil] :aggregation_key (nil) Assign an aggregation key to the event, to group it with some others
    # @option opts [String, nil] :priority ('normal') Can be "normal" or "low"
    # @option opts [String, nil] :source_type_name (nil) Assign a source type to the event
    # @option opts [String, nil] :alert_type ('info') Can be "error", "warning", "info" or "success".
    # @option opts [Boolean, false] :truncate_if_too_long (false) Truncate the event if it is too long
    # @option opts [Array<String>] :tags tags to be added to every metric
    # @example Report an awful event:
    #   $statsd.event('Something terrible happened', 'The end is near if we do nothing', :alert_type=>'warning', :tags=>['end_of_times','urgent'])
    def event(title, text, opts = EMPTY_OPTIONS)
      telemetry.sent(events: 1) if telemetry

      forwarder.send_message(serializer.to_event(title, text, opts))
    end

    # Send several metrics in the same packet.
    # They will be buffered and flushed when the block finishes.
    #
    # This method exists for compatibility with v4.x versions, it is not needed
    # anymore since the batching is now automatically done internally.
    # It also means that an automatic flush could occur if the buffer is filled
    # during the execution of the batch block.
    #
    # This method is DEPRECATED and will be removed in future v6.x API.
    #
    # @example Send several metrics in one packet:
    #   $statsd.batch do |s|
    #      s.gauge('users.online',156)
    #      s.increment('page.views')
    #    end
    def batch
      yield self
      flush(sync: true)
    end

    # Close the underlying socket
    #
    # @param [Boolean, true] flush Should we flush the metrics before closing
    def close(flush: true)
      flush(sync: true) if flush
      forwarder.close
    end

    def sync_with_outbound_io
      forwarder.sync_with_outbound_io
    end

    # Flush the buffer into the connection
    def flush(flush_telemetry: false, sync: false)
      forwarder.flush(flush_telemetry: flush_telemetry, sync: sync)
    end

    def telemetry
      forwarder.telemetry
    end

    def host
      forwarder.host
    end

    def port
      forwarder.port
    end

    def socket_path
      forwarder.socket_path
    end

    def transport_type
      forwarder.transport_type
    end

    private
    attr_reader :serializer
    attr_reader :forwarder

    EMPTY_OPTIONS = {}.freeze

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def send_stats(stat, delta, type, opts = EMPTY_OPTIONS)
      telemetry.sent(metrics: 1) if telemetry

      sample_rate = opts[:sample_rate] || @sample_rate || 1

      if sample_rate == 1 || opts[:pre_sampled] || rand <= sample_rate
        full_stat =
          if @delay_serialization
            [[stat, delta, type], {tags: opts[:tags], sample_rate: sample_rate}]
          else
            serializer.to_stat(stat, delta, type, tags: opts[:tags], sample_rate: sample_rate)
          end

        forwarder.send_message(full_stat)
      end
    end
  end
end
