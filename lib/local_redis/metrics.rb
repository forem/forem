require "active_support/fork_tracker"

module LocalRedis
  # Counts L1 reads in memory and reports totals at most once per interval per
  # process. Per-read stats calls would add a Better Stack log event per read.
  class Metrics
    INTERVAL = 60

    def self.install(store, **options)
      return unless defined?(ActiveSupport::Cache::LocalRedisCacheStore) &&
        store.is_a?(ActiveSupport::Cache::LocalRedisCacheStore)

      metrics = new(**options)
      # Called by the store directly: a Notifications subscriber costs ~4us per read.
      store.metrics = metrics
      # Puma preloads and forks; workers must not re-report the parent's counts.
      ActiveSupport::ForkTracker.after_fork { metrics.reset }
      metrics
    end

    def initialize(stats_client:, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @stats_client = stats_client
      @clock = clock
      reset
    end

    def record_read(hits, misses)
      @lock.synchronize do
        @hits += hits
        @misses += misses
      end
      flush if @clock.call >= @flush_at
    rescue StandardError
      # Metrics must never fail a cache read.
      nil
    end

    def record_bypass
      @lock.synchronize { @bypasses += 1 }
      flush if @clock.call >= @flush_at
    rescue StandardError
      nil
    end

    def reset
      # New locks: one held by another thread at fork time would never be released.
      @lock = Mutex.new
      @flush_lock = Mutex.new
      @hits = @misses = @bypasses = 0
      @flush_at = @clock.call + INTERVAL
    end

    private

    def flush
      return unless @flush_lock.try_lock

      begin
        return if @clock.call < @flush_at

        @flush_at = @clock.call + INTERVAL
        counts = @lock.synchronize do
          totals = { "hits" => @hits, "misses" => @misses, "bypasses" => @bypasses }
          @hits = @misses = @bypasses = 0
          totals
        end
        # Report outside the counting lock so reads never wait on the stats client.
        counts.each do |metric, value|
          @stats_client.count("local_redis_cache.#{metric}", value) if value.positive?
        end
      ensure
        @flush_lock.unlock
      end
    end
  end
end
