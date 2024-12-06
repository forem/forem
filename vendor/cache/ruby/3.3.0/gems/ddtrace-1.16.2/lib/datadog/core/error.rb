# frozen_string_literal: true

require_relative 'utils'

module Datadog
  module Core
    # Error is a value-object responsible for sanitizing/encapsulating error data
    class Error
      attr_reader :type, :message, :backtrace

      class << self
        def build_from(value)
          case value
          when Error then value
          when Array then new(*value)
          when Exception then new(value.class, value.message, full_backtrace(value))
          when ContainsMessage then new(value.class, value.message)
          when String then new(nil, value)
          else BlankError
          end
        end

        private

        # Returns a stack trace with nested error causes and details.
        #
        # This manually implements Ruby >= 2.6 error output for two reasons:
        #
        # 1. It is not available in Ruby < 2.6.
        # 2. It's measurably faster to manually implement it in Ruby.
        #
        # This method mimics the exact output of
        # `ex.full_message(highlight: false, order: :top)`
        # but it's around 3x faster in our benchmark test
        # at `error_spec.rb`.
        def full_backtrace(ex)
          backtrace = String.new
          backtrace_for(ex, backtrace)

          # Avoid circular causes
          causes = {}
          causes[ex] = true

          cause = ex
          while (cause = cause.cause) && !causes.key?(cause)
            backtrace_for(cause, backtrace)
            causes[cause] = true
          end

          backtrace
        end

        # Outputs the following format for exceptions:
        #
        # ```
        # error_spec.rb:55:in `wrapper': wrapper layer (RuntimeError)
        # 	from error_spec.rb:40:in `wrapper'
        # 	from error_spec.rb:61:in `caller'
        #   ...
        # ```
        def backtrace_for(ex, backtrace)
          trace = ex.backtrace
          return unless trace

          if trace[0]
            # Add Exception information to error line
            backtrace << trace[0]
            backtrace << ': '
            backtrace << ex.message.to_s
            backtrace << ' ('
            backtrace << ex.class.to_s
            backtrace << ')'
          end

          if trace[1]
            # Ident stack trace for caller lines, to separate
            # them from the main error lines.
            trace[1..-1].each do |line|
              backtrace << "\n\tfrom "
              backtrace << line
            end
          end

          backtrace << "\n"
        end
      end

      def initialize(type = nil, message = nil, backtrace = nil)
        backtrace = Array(backtrace).join("\n") unless backtrace.is_a?(String)

        @type = Utils.utf8_encode(type)
        @message = Utils.utf8_encode(message)
        @backtrace = Utils.utf8_encode(backtrace)
      end

      BlankError = Error.new
      ContainsMessage = ->(v) { v.respond_to?(:message) }
    end
  end
end
