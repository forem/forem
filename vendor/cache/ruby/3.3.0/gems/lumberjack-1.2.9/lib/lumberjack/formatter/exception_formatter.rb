# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Format an exception including the backtrace. You can specify an object that
    # responds to `call` as a backtrace cleaner. The exception backtrace will be
    # passed to this object and the returned array is what will be logged. You can
    # use this to clean out superfluous lines.
    class ExceptionFormatter
      attr_accessor :backtrace_cleaner

      # @param [#call] backtrace_cleaner An object that responds to `call` and takes
      #   an array of strings (the backtrace) and returns an array of strings (the
      def initialize(backtrace_cleaner = nil)
        self.backtrace_cleaner = backtrace_cleaner
      end

      def call(exception)
        message = "#{exception.class.name}: #{exception.message}"
        trace = exception.backtrace
        if trace
          trace = clean_backtrace(trace)
          message << "#{Lumberjack::LINE_SEPARATOR}  #{trace.join("#{Lumberjack::LINE_SEPARATOR}  ")}"
        end
        message
      end

      private

      def clean_backtrace(trace)
        if trace && backtrace_cleaner
          backtrace_cleaner.call(trace)
        else
          trace
        end
      end
    end
  end
end
