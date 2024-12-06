require_relative '../tracing/context'
require_relative '../tracing/distributed/datadog'
require_relative '../tracing/trace_operation'
require_relative 'propagator'

module Datadog
  module OpenTracer
    # OpenTracing propagator for Datadog::OpenTracer::Tracer
    module TextMapPropagator
      extend Propagator

      BAGGAGE_PREFIX = 'ot-baggage-'.freeze

      class << self
        # Inject a SpanContext into the given carrier
        #
        # @param span_context [SpanContext]
        # @param carrier [Carrier] A carrier object of Rack type
        def inject(span_context, carrier)
          # Inject baggage
          span_context.baggage.each do |key, value|
            carrier[BAGGAGE_PREFIX + key] = value
          end

          # Inject Datadog trace properties
          digest = if span_context.datadog_context && span_context.datadog_context.active_trace
                     span_context.datadog_context.active_trace.to_digest
                   else
                     span_context.datadog_trace_digest
                   end
          return unless digest

          carrier[Tracing::Distributed::Datadog::ORIGIN_KEY] = digest.trace_origin
          carrier[Tracing::Distributed::Datadog::PARENT_ID_KEY] = digest.span_id
          carrier[Tracing::Distributed::Datadog::SAMPLING_PRIORITY_KEY] = digest.trace_sampling_priority
          carrier[Tracing::Distributed::Datadog::TRACE_ID_KEY] = digest.trace_id

          nil
        end

        # Extract a SpanContext in TextMap format from the given carrier.
        #
        # @param carrier [Carrier] A carrier object of TextMap type
        # @return [SpanContext, nil] the extracted SpanContext or nil if none could be found
        def extract(carrier)
          # First extract & build a Datadog context
          headers = DistributedHeaders.new(carrier)
          datadog_trace_digest = headers_to_trace_digest(headers)

          # Then extract any other baggage
          baggage = {}
          carrier.each do |key, value|
            baggage[item_to_baggage(key)] = value if baggage_item?(key)
          end

          SpanContextFactory.build(
            datadog_context: nil,
            datadog_trace_digest: datadog_trace_digest,
            baggage: baggage
          )
        end

        private

        def headers_to_trace_digest(headers)
          return unless headers.valid?

          Datadog::Tracing::TraceDigest.new(
            span_id: headers.parent_id,
            trace_id: headers.trace_id,
            trace_origin: headers.origin,
            trace_sampling_priority: headers.sampling_priority
          )
        end

        def baggage_item?(item)
          item.to_s.start_with?(BAGGAGE_PREFIX)
        end

        def item_to_baggage(key)
          key[BAGGAGE_PREFIX.length, key.length]
        end
      end
    end
  end
end
