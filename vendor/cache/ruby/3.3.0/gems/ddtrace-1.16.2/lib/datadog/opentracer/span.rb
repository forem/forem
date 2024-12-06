require 'time'

require_relative '../tracing/metadata/ext'

module Datadog
  module OpenTracer
    # OpenTracing adapter for Datadog::Span
    # @public_api
    class Span < ::OpenTracing::Span
      attr_reader \
        :datadog_span

      def initialize(datadog_span:, span_context:)
        @datadog_span = datadog_span
        @span_context = span_context
      end

      # Set the name of the operation
      #
      # @param [String] name
      def operation_name=(name)
        datadog_span.name = name
      end

      # Span Context
      #
      # @return [SpanContext]
      def context
        @span_context
      end

      # Set a tag value on this span
      # @param key [String] the key of the tag
      # @param value [String, Numeric, Boolean] the value of the tag. If it's not
      # a String, Numeric, or Boolean it will be encoded with to_s
      def set_tag(key, value)
        # Special cases to convert opentracing tags to datadog tags
        case key
        when 'error'
          # Opentracing supports and `error: <bool>` tag, we need to convert to span status
          # DEV: Do not return, we want to still set the `error` tag as they requested
          datadog_span.status = value ? Datadog::Tracing::Metadata::Ext::Errors::STATUS : 0
        end

        tap { datadog_span.set_tag(key, value) }
      end

      # Set a baggage item on the span
      # @param key [String] the key of the baggage item
      # @param value [String] the value of the baggage item
      def set_baggage_item(key, value)
        tap do
          # SpanContext is immutable, so to make changes
          # build a new span context.
          @span_context = SpanContextFactory.clone(
            span_context: context,
            baggage: { key => value }
          )
        end
      end

      # Get a baggage item
      # @param key [String] the key of the baggage item
      # @return [String] value of the baggage item
      def get_baggage_item(key)
        context.baggage[key]
      end

      # @deprecated Use {#log_kv} instead.
      # Reason: event is an optional standard log field defined in spec and not required.  Also,
      # method name {#log_kv} is more consistent with other language implementations such as Python and Go.
      #
      # Add a log entry to this span
      # @param event [String] event name for the log
      # @param timestamp [Time] time of the log
      # @param fields [Hash] Additional information to log
      def log(event: nil, timestamp: Time.now, **fields)
        super # Log deprecation warning

        # If the fields specify an error
        datadog_span.set_error(fields[:'error.object']) if fields.key?(:'error.object')
      end

      # Add a log entry to this span
      # @param timestamp [Time] time of the log
      # @param fields [Hash] Additional information to log
      def log_kv(timestamp: Time.now, **fields)
        # If the fields specify an error
        datadog_span.set_error(fields[:'error.object']) if fields.key?(:'error.object')
      end

      # Finish the {Span}
      # @param end_time [Time] custom end time, if not now
      def finish(end_time: Time.now)
        datadog_span.finish(end_time)
      end
    end
  end
end
