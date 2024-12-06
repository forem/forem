require "time"
require "sidekiq"
require "sidekiq/metrics/shared"

# This file contains the components which track execution metrics within Sidekiq.
module Sidekiq
  module Metrics
    class ExecutionTracker
      include Sidekiq::Component

      def initialize(config)
        @config = config
        @jobs = Hash.new(0)
        @totals = Hash.new(0)
        @grams = Hash.new { |hash, key| hash[key] = Histogram.new(key) }
        @lock = Mutex.new
      end

      def track(queue, klass)
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :millisecond)
        time_ms = 0
        begin
          begin
            yield
          ensure
            finish = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :millisecond)
            time_ms = finish - start
          end
          # We don't track time for failed jobs as they can have very unpredictable
          # execution times. more important to know average time for successful jobs so we
          # can better recognize when a perf regression is introduced.
          @lock.synchronize {
            @grams[klass].record_time(time_ms)
            @jobs["#{klass}|ms"] += time_ms
            @totals["ms"] += time_ms
          }
        rescue Exception
          @lock.synchronize {
            @jobs["#{klass}|f"] += 1
            @totals["f"] += 1
          }
          raise
        ensure
          @lock.synchronize {
            @jobs["#{klass}|p"] += 1
            @totals["p"] += 1
          }
        end
      end

      LONG_TERM = 90 * 24 * 60 * 60
      MID_TERM = 7 * 24 * 60 * 60
      SHORT_TERM = 8 * 60 * 60

      def flush(time = Time.now)
        totals, jobs, grams = reset
        procd = totals["p"]
        fails = totals["f"]
        return if procd == 0 && fails == 0

        now = time.utc
        nowdate = now.strftime("%Y%m%d")
        nowhour = now.strftime("%Y%m%d|%-H")
        nowmin = now.strftime("%Y%m%d|%-H:%-M")
        count = 0

        redis do |conn|
          if grams.size > 0
            conn.pipelined do |pipe|
              grams.each do |_, gram|
                gram.persist(pipe, now)
              end
            end
          end

          [
            ["j", jobs, nowdate, LONG_TERM],
            ["j", jobs, nowhour, MID_TERM],
            ["j", jobs, nowmin, SHORT_TERM]
          ].each do |prefix, data, bucket, ttl|
            # Quietly seed the new 7.0 stats format so migration is painless.
            conn.pipelined do |xa|
              stats = "#{prefix}|#{bucket}"
              # logger.debug "Flushing metrics #{stats}"
              data.each_pair do |key, value|
                xa.hincrby stats, key, value
                count += 1
              end
              xa.expire(stats, ttl)
            end
          end
          logger.info "Flushed #{count} metrics"
          count
        end
      end

      private

      def reset
        @lock.synchronize {
          array = [@totals, @jobs, @grams]
          @totals = Hash.new(0)
          @jobs = Hash.new(0)
          @grams = Hash.new { |hash, key| hash[key] = Histogram.new(key) }
          array
        }
      end
    end

    class Middleware
      include Sidekiq::ServerMiddleware

      def initialize(options)
        @exec = options
      end

      def call(_instance, hash, queue, &block)
        @exec.track(queue, hash["wrapped"] || hash["class"], &block)
      end
    end
  end
end

if ENV["SIDEKIQ_METRICS_BETA"] == "1"
  Sidekiq.configure_server do |config|
    exec = Sidekiq::Metrics::ExecutionTracker.new(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::Metrics::Middleware, exec
    end
    config.on(:beat) do
      exec.flush
    end
  end
end
