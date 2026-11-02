require "active_support/cache/redis_cache_store"
require "active_support/core_ext/object/blank"
require_relative "../../local_redis/cache"

module ActiveSupport
  module Cache
    # Only serialized cache reads use L1. Writes and atomic operations retain
    # RedisCacheStore's authoritative Redis implementation and failure semantics.
    class LocalRedisCacheStore < RedisCacheStore
      VALUE_AND_TTL = <<~LUA.freeze
        return {redis.call('GET', KEYS[1]), redis.call('PTTL', KEYS[1])}
      LUA
      UNSUPPORTED_CONNECTION_OPTIONS = %i[redis sentinels cluster host port path db username password ssl ssl_params
                                          replica role].freeze

      # Optional LocalRedis::Metrics; counted directly to avoid per-read notification overhead.
      attr_accessor :metrics

      def initialize(local_url:, **options)
        unless options[:url].is_a?(String) && !options[:url].empty? &&
            (options.keys & UNSUPPORTED_CONNECTION_OPTIONS).empty?
          raise ArgumentError,
                "Local cache requires one URL endpoint; custom clients, sharding and Sentinel are unsupported"
        end
        if LocalRedis::Cache.same_endpoint?(options[:url], local_url)
          raise ArgumentError, "Local cache requires a separate authoritative Redis URL"
        end

        @local_max_ttl_ms = LocalRedis::Cache.max_ttl_ms
        @script_warning_lock = Mutex.new
        @l1 = LocalRedis::Cache.new(url: local_url, source_url: options.fetch(:url))
        super(**options)
      end

      # RedisCacheStore's request cache can otherwise satisfy fetch_multi before
      # read_multi_entries sees the authoritative flag.
      def fetch_multi(*names, &block)
        options = names.last.is_a?(Hash) ? names.last : {}
        return bypass_local_cache { super } if options[:raw] || options[:local_cache] == false

        super
      end

      def delete_matched(matcher, options = nil)
        super
      ensure
        local_operation { @l1.invalidate(nil) }
      end

      def clear(options = nil)
        super
      ensure
        local_operation { @l1.invalidate(nil) }
      end

      private

      def read_serialized_entry(key, raw: false, **options)
        return bypass_local_cache { super } if raw || options[:local_cache] == false

        cache = local_cache
        return read_through([key]) { super }.first unless cache

        hit = true
        payload = cache.fetch_entry(key) do
          hit = false
          read_through([key]) { super }.first
        end
        options[:event][:store] = cache.class.name if hit && options[:event]
        payload
      end

      # Matches RedisCacheStore's decoding/version/expiry checks, with batched L1
      # reads and one remote pipeline for just the misses.
      def read_multi_entries(names, **options)
        return bypass_local_cache { super } if options[:raw] || options[:local_cache] == false
        return super if names.empty?

        keys = names.map { |name| normalize_key(name, options) }
        values = read_serialized_entries(keys)
        names.zip(values).each_with_object({}) do |(name, value), results|
          entry = deserialize_entry(value)
          next if entry.nil? || entry.expired? || entry.mismatched?(normalize_version(name, options))

          begin
            results[name] = entry.value
          rescue DeserializationError
            # Treat incompatible serialized values as misses, like RedisCacheStore.
          end
        end
      end

      # Keep serialized values and nil misses in Rails' request memory, above L1.
      # Presence in this hash matters: a recorded nil must not hit either Redis.
      def read_serialized_entries(keys)
        cache = local_cache
        return read_through(keys) { redis.then { |client| client.mget(*keys) } } unless cache

        entries = cache.read_multi_entries(keys)
        missing = keys.reject { |key| entries.key?(key) }.uniq
        unless missing.empty?
          values = read_through(missing) { redis.then { |client| client.mget(*missing) } }
          missing.zip(values).each do |key, payload|
            entries[key] = payload
            cache.write_entry(key, payload)
          end
        end
        keys.map { |key| entries[key] }
      end

      def read_through(keys)
        snapshot = local_operation { @l1.read(keys) }
        if snapshot.nil?
          instrument_bypass
          return failsafe(:read_entry, returning: []) { Array(yield) }
        end

        generation, values, guards = snapshot
        missing = keys.zip(values).filter_map { |key, value| key if value.nil? }.uniq
        misses = values.count(nil)
        instrument_read(keys.size - misses, misses)
        return values if missing.empty?

        started_at = LocalRedis::Cache.monotonic_time
        entries = failsafe(:read_entry, returning: []) do
          redis.then do |client|
            client.pipelined do |pipeline|
              missing.each { |key| pipeline.eval(VALUE_AND_TTL, keys: [key]) }
            end
          end
        rescue ::Redis::CommandError => e
          warn_script_rejected(e)
          nil
        end
        # A provider may allow tracking/GET but deny EVAL. Keep its ordinary
        # cache readable on command rejection. Transport/pool failures return []
        # above, preserving local hits without a second timeout or error report.
        if entries.nil?
          fallback = failsafe(:read_entry, returning: []) { Array(yield) }
          return values.zip(fallback).map { |local_value, remote_value| local_value || remote_value }
        end

        fetched = missing.zip(entries).to_h
        elapsed = ((LocalRedis::Cache.monotonic_time - started_at) * 1000).ceil
        local_operation { @l1.fill(generation, cacheable_entries(fetched, elapsed), keys.zip(guards).to_h) }
        keys.zip(values).map { |key, value| value || fetched[key]&.first }
      end

      def instrument_bypass
        ActiveSupport::Notifications.instrument("bypass.local_redis_cache")
        @metrics&.record_bypass
      end

      def warn_script_rejected(error)
        return if @script_warning_pid == Process.pid

        @script_warning_lock.synchronize do
          return if @script_warning_pid == Process.pid

          @script_warning_pid = Process.pid
          logger&.warn("LocalRedisCacheStore: hosted Redis rejected the read-through script (#{error.class}); " \
                       "using GET/MGET without filling L1. Check EVAL/GET/PTTL permissions.")
        end
      rescue StandardError
        # Logging must never prevent the ordinary hosted-read fallback.
        nil
      end

      def instrument_read(hits, misses)
        ActiveSupport::Notifications.instrument("read.local_redis_cache", hits: hits, misses: misses)
        @metrics&.record_read(hits, misses)
      end

      def cacheable_entries(fetched, elapsed)
        fetched.each_with_object({}) do |(key, result), memo|
          next unless result&.first

          value, ttl = result
          ttl = ttl == -1 ? @local_max_ttl_ms : [ttl - elapsed, @local_max_ttl_ms].min
          memo[key] = [value, ttl] if ttl.positive?
        end
      end

      # Evict synchronously on this host, including when a remote write fails.
      # Tracking handles other hosts and writers from older app releases.
      # Counters (increment/decrement) skip this: they are raw values read only
      # with raw: true, which bypasses L1, and run on every throttled request.
      def write_serialized_entry(key, payload, **options)
        super
      ensure
        local_operation { @l1.invalidate([key]) } unless options[:pipeline]
      end

      def write_multi_entries(entries, **options)
        super
      ensure
        local_operation { @l1.invalidate(entries.keys) }
      end

      def delete_entry(key, **options)
        super
      ensure
        local_operation { @l1.invalidate([key]) }
      end

      def delete_multi_entries(entries, **options)
        entries.each { |key| local_cache&.delete_entry(key) }
        super
      ensure
        local_operation { @l1.invalidate(entries) }
      end

      def local_operation
        yield
      rescue ::Redis::BaseError, ConnectionPool::Error, ConnectionPool::TimeoutError
        # L1 is optional. The existing L2 failsafe/error reporter still handles
        # authoritative Redis errors; a local outage must not drop remote reads.
        nil
      end
    end
  end
end
