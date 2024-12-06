# frozen_string_literal: true

module Datadog
  module OpenTracer
    # OpenTracing adapter for SpanContext
    # @public_api
    class SpanContext < ::OpenTracing::SpanContext
      attr_reader \
        :datadog_context,
        :datadog_trace_digest

      def initialize(datadog_context:, datadog_trace_digest: nil, baggage: {})
        @datadog_context = datadog_context
        @datadog_trace_digest = datadog_trace_digest
        @baggage = baggage.freeze
      end
    end
  end
end
