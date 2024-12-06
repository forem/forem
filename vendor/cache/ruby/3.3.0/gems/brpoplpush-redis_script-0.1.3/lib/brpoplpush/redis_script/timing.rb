# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    # Handles timing> of things
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
        start_time = now

        [yield, now - start_time]
      end

      #
      # Returns a float representation of the current time.
      #   Either from Process or Time
      #
      #
      # @return [Float]
      #
      def now
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i
      end
    end
  end
end
