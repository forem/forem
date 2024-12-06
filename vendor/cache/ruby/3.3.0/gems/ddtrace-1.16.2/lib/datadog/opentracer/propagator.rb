# frozen_string_literal: true

module Datadog
  module OpenTracer
    # OpenTracing propagator for Datadog::OpenTracer::Tracer
    # @abstract
    # @public_api
    module Propagator
      # Inject a SpanContext into the given carrier
      #
      # @param span_context [SpanContext]
      # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
      def inject(span_context, carrier)
        raise NotImplementedError
      end

      # Extract a SpanContext in the given format from the given carrier.
      #
      # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
      # @return [SpanContext, nil] the extracted SpanContext or nil if none could be found
      def extract(carrier)
        raise NotImplementedError
      end
    end
  end
end
