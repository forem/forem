# frozen_string_literal: true

require_relative 'processor'

module Datadog
  module AppSec
    # Capture context essential to consistently call processor and report via traces
    class Scope
      attr_reader :trace, :service_entry_span, :processor_context

      def initialize(trace, service_entry_span, processor_context)
        @trace = trace
        @service_entry_span = service_entry_span
        @processor_context = processor_context
      end

      def finalize
        @processor_context.finalize
      end

      class << self
        def activate_scope(trace, service_entry_span, processor)
          raise ActiveScopeError, 'another scope is active, nested scopes are not supported' if active_scope

          context = Datadog::AppSec::Processor::Context.new(processor)

          self.active_scope = new(trace, service_entry_span, context)
        end

        def deactivate_scope
          raise InactiveScopeError, 'no scope is active, nested scopes are not supported' unless active_scope

          scope = active_scope

          reset_active_scope

          scope.finalize
        end

        def active_scope
          Thread.current[:datadog_appsec_active_scope]
        end

        private

        def active_scope=(scope)
          raise ArgumentError, 'not a Datadog::AppSec::Scope' unless scope.instance_of?(Scope)

          Thread.current[:datadog_appsec_active_scope] = scope
        end

        def reset_active_scope
          Thread.current[:datadog_appsec_active_scope] = nil
        end
      end

      class InactiveScopeError < StandardError; end
      class ActiveScopeError < StandardError; end
    end
  end
end
