# frozen_string_literal: true

require "concurrent-ruby"

module Ferrum
  module Utils
    module ElapsedTime
      module_function

      def start
        @start ||= monotonic_time
      end

      def elapsed_time(start = nil)
        monotonic_time - (start || @start)
      end

      def monotonic_time
        Concurrent.monotonic_time
      end

      def timeout?(start, timeout)
        elapsed_time(start) > timeout
      end
    end
  end
end
