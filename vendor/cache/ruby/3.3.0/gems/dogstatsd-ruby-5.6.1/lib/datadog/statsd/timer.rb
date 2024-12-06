# frozen_string_literal: true

module Datadog
  class Statsd
    class Timer
      def initialize(interval, &callback)
        @mx = Mutex.new
        @cv = ConditionVariable.new
        @interval = interval
        @callback = callback
        @stop = true
        @thread = nil
      end

      def start
        return unless stop?

        @stop = false
        @thread = Thread.new do
          last_execution_time = current_time
          @mx.synchronize do
            until @stop
              timeout = @interval - (current_time - last_execution_time)
              @cv.wait(@mx, timeout > 0 ? timeout : 0)
              last_execution_time = current_time
              @callback.call
            end
          end
        end
        @thread.name = 'Statsd Timer' unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
      end

      def stop
        return if @thread.nil?

        @stop = true
        @mx.synchronize do
          @cv.signal
        end
        @thread.join
        @thread = nil
      end

      def stop?
        @thread.nil? || @thread.stop?
      end

      private

      if Process.const_defined?(:CLOCK_MONOTONIC)
        def current_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      else
        def current_time
          Time.now
        end
      end
    end
  end
end
