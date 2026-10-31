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

      def initialize(local_url:, **options)
        unless options[:url].is_a?(String) && !options[:url].empty? &&
            (options.keys & UNSUPPORTED_CONNECTION_OPTIONS).empty?
          raise ArgumentError,
                "Local cache requires one URL endpoint; custom clients, sharding and Sentinel are unsupported"
        end
        if LocalRedis::Cache.same_endpoint?(options[:url], local_url)
          raise ArgumentError, "Local cache requires a separate authoritative Redis URL"
        end

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

        read_through([key]) { super }.first
      end

      # Matches RedisCacheStore's decoding/version/expiry checks, with batched L1
      # reads and one remote pipeline for just the misses.
      def read_multi_entries(names, **options)
        return bypass_local_cache { super } if options[:raw] || options[:local_cache] == false
        return super if names.empty?

        keys = names.map { |name| normalize_key(name, options) }
        values = read_through(keys) { redis.then { |client| client.mget(*keys) } }
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

      def read_through(keys)
        snapshot = local_operation { @l1.read(keys) }
        if snapshot.blank?
          ActiveSupport::Notifications.instrument("bypass.local_redis_cache")
          return failsafe(:read_entry, returning: []) { Array(yield) }
        end

        generation, *values = snapshot
        missing = keys.zip(values).filter_map { |key, value| key if value.nil? }.uniq
        misses = values.count(nil)
        ActiveSupport::Notifications.instrument("read.local_redis_cache", hits: keys.size - misses, misses: misses)
        return values if missing.empty?

        started_at = LocalRedis::Cache.monotonic_time
        entries = failsafe(:read_entry, returning: []) do
          redis.then do |client|
            client.pipelined do |pipeline|
              missing.each { |key| pipeline.eval(VALUE_AND_TTL, keys: [key]) }
            end
          end
        rescue ::Redis::CommandError
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
        local_operation { @l1.fill(generation, cacheable_entries(fetched, elapsed)) }
        keys.zip(values).map { |key, value| value || fetched[key]&.first }
      end

      def cacheable_entries(fetched, elapsed)
        fetched.each_with_object({}) do |(key, result), memo|
          next unless result&.first

          value, ttl = result
          ttl = ttl == -1 ? LocalRedis::Cache::MAX_TTL_MS : [ttl - elapsed, LocalRedis::Cache::MAX_TTL_MS].min
          memo[key] = [value, ttl] if ttl.positive?
        end
      end

      # Evict synchronously on this host, including when a remote write fails.
      # Tracking handles other hosts and writers from older app releases.
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
        super
      ensure
        local_operation { @l1.invalidate(entries) }
      end

      def change_counter(key, amount, options)
        super
      ensure
        local_operation { @l1.invalidate([key]) }
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
