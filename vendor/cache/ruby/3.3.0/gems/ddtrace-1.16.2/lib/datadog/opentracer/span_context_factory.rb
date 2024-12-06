# frozen_string_literal: true

module Datadog
  module OpenTracer
    # Creates new Datadog::OpenTracer::SpanContext
    module SpanContextFactory
      module_function

      def build(datadog_context:, datadog_trace_digest: nil, baggage: {})
        SpanContext.new(
          datadog_context: datadog_context,
          datadog_trace_digest: datadog_trace_digest,
          baggage: baggage.dup
        )
      end

      def clone(span_context:, baggage: {})
        SpanContext.new(
          datadog_context: span_context.datadog_context,
          datadog_trace_digest: span_context.datadog_trace_digest,
          # Merge baggage from previous SpanContext
          baggage: span_context.baggage.merge(baggage)
        )
      end
    end
  end
end
