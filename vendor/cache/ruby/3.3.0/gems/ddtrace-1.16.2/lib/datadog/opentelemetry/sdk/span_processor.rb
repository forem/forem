# frozen_string_literal: true

module Datadog
  module OpenTelemetry
    module SDK
      # Keeps OpenTelemetry spans in sync with the Datadog execution context.
      # Also responsible for flushing spans when their are finished.
      class SpanProcessor
        # Called when a {Span} is started, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        # @param [Context] parent_context the parent {Context} of the newly
        #  started span.
        def on_start(span, parent_context)
          create_matching_datadog_span(span, parent_context)
        end

        # Called when a {Span} is ended, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span)
          span.datadog_span.finish(ns_to_time(span.end_timestamp))
        end

        # Export all ended spans to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          writer.force_flush(timeout: timeout) if writer.respond_to? :force_flush
          Export::SUCCESS
        end

        # Called when {TracerProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          writer.stop
          Export::SUCCESS
        end

        private

        def writer
          Datadog.configuration.tracing.writer
        end

        def create_matching_datadog_span(span, parent_context)
          if parent_context.trace
            Tracing.send(:tracer).send(:call_context).activate!(parent_context.ensure_trace)
          else
            Tracing.continue_trace!(nil)
          end

          datadog_span = start_datadog_span(span)

          span.datadog_span = datadog_span
          span.datadog_trace = Tracing.active_trace
        end

        def start_datadog_span(span)
          tags = span.resource.attribute_enumerator.to_h

          kind = span.kind || 'internal'
          tags[Tracing::Metadata::Ext::TAG_KIND] = kind

          datadog_span = Tracing.trace(
            span.name,
            tags: tags,
            start_time: ns_to_time(span.start_timestamp)
          )

          datadog_span.set_error([nil, span.status.description]) unless span.status.ok?
          datadog_span.set_tags(span.attributes)

          datadog_span
        end

        # From nanoseconds, used by OpenTelemetry, to a {Time} object, used by the Datadog Tracer.
        def ns_to_time(timestamp_ns)
          Time.at(timestamp_ns / 1000000000.0)
        end
      end
    end
  end
end
