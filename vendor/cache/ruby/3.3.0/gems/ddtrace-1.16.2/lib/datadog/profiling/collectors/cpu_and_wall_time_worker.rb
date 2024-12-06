module Datadog
  module Profiling
    module Collectors
      # Used to trigger the periodic execution of Collectors::ThreadState, which implements all of the sampling logic
      # itself; this class only implements the "when to do it" part.
      # Almost all of this class is implemented as native code.
      #
      # Methods prefixed with _native_ are implemented in `collectors_cpu_and_wall_time_worker.c`
      class CpuAndWallTimeWorker
        private

        attr_accessor :failure_exception

        public

        def initialize(
          gc_profiling_enabled:,
          allocation_counting_enabled:,
          no_signals_workaround_enabled:,
          thread_context_collector:,
          idle_sampling_helper: IdleSamplingHelper.new,
          # **NOTE**: This should only be used for testing; disabling the dynamic sampling rate will increase the
          # profiler overhead!
          dynamic_sampling_rate_enabled: true,
          allocation_sample_every: 0 # Currently only for testing; Setting this to > 0 can add a lot of overhead!
        )
          unless dynamic_sampling_rate_enabled
            Datadog.logger.warn(
              'Profiling dynamic sampling rate disabled. This should only be used for testing, and will increase overhead!'
            )
          end

          if allocation_counting_enabled && allocation_sample_every > 0
            Datadog.logger.warn(
              "Enabled experimental allocation profiling: allocation_sample_every=#{allocation_sample_every}. This is " \
              'experimental, not recommended, and will increase overhead!'
            )
          end

          self.class._native_initialize(
            self,
            thread_context_collector,
            gc_profiling_enabled,
            idle_sampling_helper,
            allocation_counting_enabled,
            no_signals_workaround_enabled,
            dynamic_sampling_rate_enabled,
            allocation_sample_every,
          )
          @worker_thread = nil
          @failure_exception = nil
          @start_stop_mutex = Mutex.new
          @idle_sampling_helper = idle_sampling_helper
        end

        def start(on_failure_proc: nil)
          @start_stop_mutex.synchronize do
            return if @worker_thread && @worker_thread.alive?

            Datadog.logger.debug { "Starting thread for: #{self}" }

            @idle_sampling_helper.start

            @worker_thread = Thread.new do
              begin
                Thread.current.name = self.class.name

                self.class._native_sampling_loop(self)

                Datadog.logger.debug('CpuAndWallTimeWorker thread stopping cleanly')
              rescue Exception => e # rubocop:disable Lint/RescueException
                @failure_exception = e
                Datadog.logger.warn(
                  'CpuAndWallTimeWorker thread error. ' \
                  "Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
                )
                on_failure_proc&.call
              end
            end
            @worker_thread.name = self.class.name # Repeated from above to make sure thread gets named asap
          end

          true
        end

        def stop
          @start_stop_mutex.synchronize do
            Datadog.logger.debug('Requesting CpuAndWallTimeWorker thread shut down')

            @idle_sampling_helper.stop

            return unless @worker_thread

            self.class._native_stop(self, @worker_thread)

            @worker_thread.join
            @worker_thread = nil
            @failure_exception = nil
          end
        end

        def reset_after_fork
          self.class._native_reset_after_fork(self)
        end

        def stats
          self.class._native_stats(self)
        end
      end
    end
  end
end
