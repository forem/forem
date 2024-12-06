module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N seconds.
      class IntervalSynchronizer
        # Private: Number of seconds between syncs (default: 10).
        DEFAULT_INTERVAL = 10

        # Public: The Float or Integer number of seconds between invocations of
        # the wrapped synchronizer.
        attr_reader :interval

        # Public: Initializes a new interval synchronizer.
        #
        # synchronizer - The Synchronizer to call when the interval has passed.
        # interval - The Integer number of seconds between invocations of
        #            the wrapped synchronizer.
        def initialize(synchronizer, interval: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL
          # TODO: add jitter to this so all processes booting at the same time
          # don't phone home at the same time.
          @last_sync_at = 0
        end

        def call
          return unless time_to_sync?

          @last_sync_at = now
          @synchronizer.call

          nil
        end

        private

        def time_to_sync?
          seconds_since_last_sync = now - @last_sync_at
          seconds_since_last_sync >= @interval
        end

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        end
      end
    end
  end
end
