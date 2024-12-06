# frozen_string_literal: true

module Datadog
  module Tracing
    module Sampling
      # Checks if a trace conforms to a matching criteria.
      # @abstract
      # @public_api
      class Matcher
        # Returns `true` if the trace should conforms to this rule, `false` otherwise
        #
        # @param [TraceOperation] trace
        # @return [Boolean]
        def match?(trace)
          raise NotImplementedError
        end
      end

      # A {Datadog::Sampling::Matcher} that supports matching a trace by
      # trace name and/or service name.
      # @public_api
      class SimpleMatcher < Matcher
        # Returns `true` for case equality (===) with any object
        MATCH_ALL = Class.new do
          # DEV: A class that implements `#===` is ~20% faster than
          # DEV: a `Proc` that always returns `true`.
          def ===(other)
            true
          end
        end.new

        attr_reader :name, :service

        # @param name [String,Regexp,Proc] Matcher for case equality (===) with the trace name,
        #             defaults to always match
        # @param service [String,Regexp,Proc] Matcher for case equality (===) with the service name,
        #                defaults to always match
        def initialize(name: MATCH_ALL, service: MATCH_ALL)
          super()
          @name = name
          @service = service
        end

        def match?(trace)
          name === trace.name && service === trace.service
        end
      end

      # A {Datadog::Tracing::Sampling::Matcher} that allows for arbitrary trace matching
      # based on the return value of a provided block.
      # @public_api
      class ProcMatcher < Matcher
        attr_reader :block

        # @yield [name, service] Provides trace name and service to the block
        # @yieldreturn [Boolean] Whether the trace conforms to this matcher
        def initialize(&block)
          super()
          @block = block
        end

        def match?(trace)
          block.call(trace.name, trace.service)
        end
      end
    end
  end
end
