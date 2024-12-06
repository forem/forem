# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles timing of things
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Timing
    module_function

    #
    # Used for timing method calls
    #
    #
    # @return [yield return, Float]
    #
    def timed
      start_time = time_source.call

      [yield, time_source.call - start_time]
    end

    #
    # Used to get a current representation of time as Integer
    #
    #
    # @return [Integer]
    #
    def time_source
      -> { (clock_stamp * 1000).to_i }
    end

    #
    # Returns the current time as float
    #
    # @see SidekiqUniqueJobs.now_f
    #
    # @return [Float]
    #
    def now_f
      SidekiqUniqueJobs.now_f
    end

    #
    # Returns a float representation of the current time.
    #   Either from Process or Time
    #
    #
    # @return [Float]
    #
    def clock_stamp
      if Process.const_defined?(:CLOCK_MONOTONIC)
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      else
        now_f
      end
    end
  end
end
