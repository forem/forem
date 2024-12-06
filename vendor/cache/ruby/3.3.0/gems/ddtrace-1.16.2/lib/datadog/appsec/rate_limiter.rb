module Datadog
  module AppSec
    # Simple per-thread rate limiter
    # Since AppSec marks sampling to keep on a security event, this limits the flood of egress traces involving AppSec
    class RateLimiter
      def initialize(rate)
        @rate = rate
        @timestamps = []
      end

      def limit
        now = Time.now.to_f

        loop do
          oldest = @timestamps.first

          break if oldest.nil? || now - oldest < 1

          @timestamps.shift
        end

        @timestamps << now

        if (count = @timestamps.count) <= @rate
          yield
        else
          Datadog.logger.debug { "Rate limit hit: #{count}/#{@rate} AppSec traces/second" }
        end
      end

      class << self
        def limit(name, &block)
          rate_limiter(name).limit(&block)
        end

        # reset a rate limiter: used for testing
        def reset!(name)
          Thread.current[:datadog_security_trace_rate_limiter] = nil
        end

        protected

        def rate_limiter(name)
          case name
          when :traces
            Thread.current[:datadog_security_trace_rate_limiter] ||= RateLimiter.new(trace_rate_limit)
          else
            raise "unsupported rate limiter: #{name.inspect}"
          end
        end

        def trace_rate_limit
          Datadog.configuration.appsec.trace_rate_limit
        end
      end
    end
  end
end
