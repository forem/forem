# frozen_string_literal: true

require "concurrent/version"

module SidekiqUniqueJobs
  module Orphans
    #
    # Manages the orphan reaper
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Manager
      module_function

      #
      # @return [Float] the amount to add to the reaper interval
      DRIFT_FACTOR = 0.02
      #
      # @return [Symbol] allowed reapers (:ruby or :lua)
      REAPERS      = [:ruby, :lua].freeze

      # includes "SidekiqUniqueJobs::Connection"
      # @!parse include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Connection
      # includes "SidekiqUniqueJobs::Logging"
      # @!parse include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Logging

      #
      # Starts a separate thread that periodically reaps orphans
      #
      #
      # @return [SidekiqUniqueJobs::TimerTask] the task that was started
      #
      def start(test_task = nil) # rubocop:disable
        return if disabled?
        return if registered?

        self.task = test_task || default_task

        with_logging_context do
          register_reaper_process
          log_info("Starting Reaper")

          task.add_observer(Observer.new)
          task.execute
          task
        end
      end

      #
      # Stops the thread that reaps orphans
      #
      #
      # @return [Boolean]
      #
      def stop
        return if disabled?
        return if unregistered?

        with_logging_context do
          log_info("Stopping Reaper")
          unregister_reaper_process
          task.shutdown
        end
      end

      #
      # The task that runs the reaper
      #
      #
      # @return [<type>] <description>
      #
      def task
        @task ||= default_task # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
      end

      #
      # A properly configured timer task
      #
      #
      # @return [SidekiqUniqueJobs::TimerTask]
      #
      def default_task
        SidekiqUniqueJobs::TimerTask.new(timer_task_options) do
          with_logging_context do
            redis do |conn|
              refresh_reaper_mutex
              Orphans::Reaper.call(conn)
            end
          end
        end
      end

      #
      # Store a task to use for scheduled execution
      #
      # @param [SidekiqUniqueJobs::TimerTask] task the task to use
      #
      # @return [void]
      #
      def task=(task)
        @task = task # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
      end

      #
      # Arguments passed on to the timer task
      #
      #
      # @return [Hash]
      #
      def timer_task_options
        { run_now: true, execution_interval: reaper_interval }
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper
      #
      def reaper
        SidekiqUniqueJobs.config.reaper
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_interval
      #
      def reaper_interval
        SidekiqUniqueJobs.config.reaper_interval
      end

      #
      # A context to use for all log entries
      #
      #
      # @return [Hash] when logger responds to `:with_context`
      # @return [String] when logger does not responds to `:with_context`
      #
      def logging_context
        if logger_context_hash?
          { "uniquejobs" => "reaper" }
        else
          "uniquejobs=orphan-reaper"
        end
      end

      #
      # Checks if a reaper is registered
      #
      #
      # @return [true, false]
      #
      def registered?
        redis do |conn|
          conn.get(UNIQUE_REAPER).to_i + drift_reaper_interval > current_timestamp
        end
      end

      #
      # Checks if that reapers are not registerd
      #
      # @see registered?
      #
      # @return [true, false]
      #
      def unregistered?
        !registered?
      end

      #
      # Checks if reaping is disabled
      #
      # @see enabled?
      #
      # @return [true, false]
      #
      def disabled?
        !enabled?
      end

      #
      # Checks if reaping is enabled
      #
      # @return [true, false]
      #
      def enabled?
        REAPERS.include?(reaper)
      end

      #
      # Writes a mutex key to redis
      #
      #
      # @return [void]
      #
      def register_reaper_process
        redis { |conn| conn.set(UNIQUE_REAPER, current_timestamp, nx: true, ex: drift_reaper_interval) }
      end

      #
      # Updates mutex key
      #
      #
      # @return [void]
      #
      def refresh_reaper_mutex
        redis { |conn| conn.set(UNIQUE_REAPER, current_timestamp, ex: drift_reaper_interval) }
      end

      #
      # Removes mutex key from redis
      #
      #
      # @return [void]
      #
      def unregister_reaper_process
        redis { |conn| conn.del(UNIQUE_REAPER) }
      end

      #
      # Reaper interval with a little drift
      #   Redis isn't exact enough so to give a little bufffer,
      #   we add a tiny value to the reaper interval.
      #
      #
      # @return [Integer] <description>
      #
      def drift_reaper_interval
        reaper_interval + (reaper_interval * DRIFT_FACTOR).to_i
      end

      #
      # Current time (as integer value)
      #
      #
      # @return [Integer]
      #
      def current_timestamp
        Time.now.to_i
      end
    end
  end
end
