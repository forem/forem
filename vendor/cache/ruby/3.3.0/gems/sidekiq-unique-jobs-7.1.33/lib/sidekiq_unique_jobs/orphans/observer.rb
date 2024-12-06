# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class DeleteOrphans provides deletion of orphaned digests
  #
  # @note this is a much slower version of the lua script but does not crash redis
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module Orphans
    #
    # Observes the Orphan::Manager and provides information about each execution
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Observer
      include SidekiqUniqueJobs::Logging

      #
      # Runs every time the {Manager} executes the TimerTask
      #   used for logging information about the reaping
      #
      # @param [Time] time the time of the execution
      # @param [Object] result the result of the execution
      # @param [Exception] ex any error raised from the TimerTask
      #
      # @return [<type>] <description>
      #
      def update(time, result, ex)
        if result
          log_info("(#{time}) Execution successfully returned #{result}")
        elsif ex.is_a?(Concurrent::TimeoutError)
          log_warn("(#{time}) Execution timed out")
        else
          log_info("(#{time}) Cleanup failed with error #{ex.message}")
          log_error(ex)
        end
      end
    end
  end
end
