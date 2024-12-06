module Backport
  module Server
    # A Backport periodical interval server.
    #
    class Interval < Base
      # @param period [Float] The interval time in seconds.
      # @param block [Proc] The proc to run on each interval.
      # @yieldparam [Interval]
      def initialize period, &block
        @period = period
        @block = block
        @ready = false
        @mutex = Mutex.new
      end

      def starting
        @ready = false
        run_ready_thread
      end

      def tick
        return unless @ready
        @mutex.synchronize do
          @block.call self
          @ready = false
        end
      end

      private

      # @return [void]
      def run_ready_thread
        Thread.new do
          until stopped?
            sleep @period
            break if stopped?
            @mutex.synchronize { @ready = true }
            changed
            notify_observers self
          end
        end
      end
    end
  end
end
