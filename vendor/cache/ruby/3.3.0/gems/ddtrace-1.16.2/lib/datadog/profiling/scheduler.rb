require_relative '../core/utils/time'

require_relative '../core/worker'
require_relative '../core/workers/polling'

module Datadog
  module Profiling
    # Periodically (every DEFAULT_INTERVAL_SECONDS) takes a profile from the `Exporter` and reports it using the
    # configured transport. Runs on its own background thread.
    class Scheduler < Core::Worker
      include Core::Workers::Polling

      DEFAULT_INTERVAL_SECONDS = 60
      MINIMUM_INTERVAL_SECONDS = 0

      # We sleep for at most this duration seconds before reporting data to avoid multi-process applications all
      # reporting profiles at the exact same time
      DEFAULT_FLUSH_JITTER_MAXIMUM_SECONDS = 3

      private

      attr_reader \
        :exporter,
        :transport

      public

      def initialize(
        exporter:,
        transport:,
        fork_policy: Core::Workers::Async::Thread::FORK_POLICY_RESTART, # Restart in forks by default
        interval: DEFAULT_INTERVAL_SECONDS,
        enabled: true
      )
        @exporter = exporter
        @transport = transport

        # Workers::Async::Thread settings
        self.fork_policy = fork_policy

        # Workers::IntervalLoop settings
        self.loop_base_interval = interval

        # Workers::Polling settings
        self.enabled = enabled
      end

      def start(on_failure_proc: nil)
        perform(on_failure_proc)
      end

      def perform(on_failure_proc)
        begin
          # A profiling flush may be called while the VM is shutting down, to report the last profile. When we do so,
          # we impose a strict timeout. This means this last profile may or may not be sent, depending on if the flush can
          # successfully finish in the strict timeout.
          # This can be somewhat confusing (why did it not get reported?), so let's at least log what happened.
          interrupted = true

          flush_and_wait
          interrupted = false
        rescue Exception => e # rubocop:disable Lint/RescueException
          Datadog.logger.warn(
            'Profiling::Scheduler thread error. ' \
            "Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
          )
          on_failure_proc&.call
          raise
        ensure
          Datadog.logger.debug('#flush was interrupted or failed before it could complete') if interrupted
        end
      end

      # Configure Workers::IntervalLoop to not report immediately when scheduler starts
      #
      # When a scheduler gets created (or reset), we don't want it to immediately try to flush; we want it to wait for
      # the loop wait time first. This avoids an issue where the scheduler reported a mostly-empty profile if the
      # application just started but this thread took a bit longer so there's already profiling data in the exporter.
      def loop_wait_before_first_iteration?
        true
      end

      def work_pending?
        exporter.can_flush?
      end

      def reset_after_fork
        exporter.reset_after_fork
      end

      private

      def flush_and_wait
        run_time = Core::Utils::Time.measure do
          flush_events
        end

        # Update wait time to try to wake consistently on time.
        # Don't drop below the minimum interval.
        self.loop_wait_time = [loop_base_interval - run_time, MINIMUM_INTERVAL_SECONDS].max
      end

      def flush_events
        # Collect data to be exported
        flush = exporter.flush

        return false unless flush

        # Sleep for a bit to cause misalignment between profilers in multi-process applications
        #
        # When not being run in a loop, it means the scheduler has not been started or was stopped, and thus
        # a) it's being shut down (and is trying to report the last profile)
        # b) it's being run as a one-shot, usually in a test
        # ...so in those cases we don't sleep
        #
        # During PR review (https://github.com/DataDog/dd-trace-rb/pull/1807) we discussed the possible alternative of
        # just sleeping before starting the scheduler loop. We ended up not going with that option to avoid the first
        # profile containing up to DEFAULT_INTERVAL_SECONDS + DEFAULT_FLUSH_JITTER_MAXIMUM_SECONDS instead of the
        # usual DEFAULT_INTERVAL_SECONDS size.
        if run_loop?
          jitter_seconds = rand * DEFAULT_FLUSH_JITTER_MAXIMUM_SECONDS # floating point number between (0.0...maximum)
          sleep(jitter_seconds)
        end

        begin
          transport.export(flush)
        rescue StandardError => e
          Datadog.logger.error(
            "Unable to report profile. Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
          )
        end

        true
      end
    end
  end
end
