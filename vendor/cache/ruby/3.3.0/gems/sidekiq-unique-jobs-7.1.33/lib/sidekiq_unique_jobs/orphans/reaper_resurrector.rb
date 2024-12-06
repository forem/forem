# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    # Restarts orphan manager if it is considered dead
    module ReaperResurrector
      module_function

      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Logging

      DRIFT_FACTOR = 0.1
      REAPERS = [:ruby, :lua].freeze

      #
      # Starts reaper resurrector that watches orphans reaper
      #
      # @return [SidekiqUniqueJobs::TimerTask] the task that was started
      #
      def start
        return if resurrector_disabled?
        return if reaper_disabled?

        with_logging_context do
          run_task
        end
      end

      #
      # Runs reaper resurrector task
      #
      # @return [SidekiqUniqueJobs::TimerTask]
      def run_task
        log_info("Starting Reaper Resurrector")
        task.execute
        task
      end

      #
      # The task that runs the resurrector
      #
      # @return [SidekiqUniqueJobs::TimerTask]
      def task
        SidekiqUniqueJobs::TimerTask.new(timer_task_options) do
          with_logging_context do
            restart_if_dead
          end
        end
      end

      #
      # Starts new instance of orphan reaper if reaper is considered dead (reaper mutex has not been refreshed lately)
      #
      def restart_if_dead
        return if reaper_registered?

        log_info("Reaper is considered dead. Starting new reaper instance")
        orphans_manager.start
      end

      #
      # Returns orphan manager
      #
      # @return [SidekiqUniqueJobs::Orphans::Manager]
      def orphans_manager
        SidekiqUniqueJobs::Orphans::Manager
      end

      #
      # Checks if resurrector is disabled
      #
      # @see resurrector_enabled?
      #
      # @return [true, false]
      def resurrector_disabled?
        !resurrector_enabled?
      end

      #
      # Checks if resurrector is enabled
      #
      # @return [true, false]
      def resurrector_enabled?
        SidekiqUniqueJobs.config.reaper_resurrector_enabled
      end

      #
      # Checks if reaping is disabled
      #
      # @see reaper_enabled?
      #
      # @return [true, false]
      #
      def reaper_disabled?
        !reaper_enabled?
      end

      #
      # Checks if reaping is enabled
      #
      # @return [true, false]
      #
      def reaper_enabled?
        REAPERS.include?(reaper)
      end

      #
      # Checks if reaper is registered
      #
      # @return [true, false]
      def reaper_registered?
        redis do |conn|
          conn.get(UNIQUE_REAPER).to_i + drift_reaper_interval > current_timestamp
        end
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper
      #
      def reaper
        SidekiqUniqueJobs.config.reaper
      end

      #
      # Arguments passed on to the timer task
      #
      #
      # @return [Hash]
      #
      def timer_task_options
        { run_now: false,
          execution_interval: reaper_resurrector_interval }
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
          { "uniquejobs" => "reaper-resurrector" }
        else
          "uniquejobs=reaper-resurrector"
        end
      end

      #
      # @see SidekiqUniqueJobs::Config#reaper_resurrector_interval
      #
      def reaper_resurrector_interval
        SidekiqUniqueJobs.config.reaper_resurrector_interval
      end

      def reaper_interval
        SidekiqUniqueJobs.config.reaper_interval
      end

      def drift_reaper_interval
        reaper_interval + (reaper_interval * DRIFT_FACTOR).to_i
      end

      def current_timestamp
        Time.now.to_i
      end
    end
  end
end
