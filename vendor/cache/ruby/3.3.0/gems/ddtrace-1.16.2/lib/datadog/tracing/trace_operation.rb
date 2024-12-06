require_relative '../core/environment/identity'
require_relative '../core/utils'

require_relative 'event'
require_relative 'metadata/tagging'
require_relative 'sampling/ext'
require_relative 'span_operation'
require_relative 'trace_digest'
require_relative 'trace_segment'
require_relative 'utils'

module Datadog
  module Tracing
    # Represents the act of tracing a series of operations,
    # by generating and collecting span measurements.
    # When completed, it yields a trace.
    #
    # Supports synchronous code flow *only*. Usage across
    # multiple threads will result in incorrect relationships.
    # For async support, a {Datadog::Tracing::TraceOperation} should be employed
    # per execution context (e.g. Thread, etc.)
    #
    # @public_api
    class TraceOperation
      include Metadata::Tagging

      DEFAULT_MAX_LENGTH = 100_000

      attr_accessor \
        :agent_sample_rate,
        :hostname,
        :origin,
        :rate_limiter_rate,
        :rule_sample_rate,
        :sample_rate,
        :sampling_priority

      attr_reader \
        :active_span_count,
        :active_span,
        :id,
        :max_length,
        :parent_span_id,
        :trace_state,
        :trace_state_unknown_fields

      attr_writer \
        :name,
        :resource,
        :sampled,
        :service

      def initialize(
        agent_sample_rate: nil,
        events: nil,
        hostname: nil,
        id: nil,
        max_length: DEFAULT_MAX_LENGTH,
        name: nil,
        origin: nil,
        parent_span_id: nil,
        rate_limiter_rate: nil,
        resource: nil,
        rule_sample_rate: nil,
        sample_rate: nil,
        sampled: nil,
        sampling_priority: nil,
        service: nil,
        profiling_enabled: nil,
        tags: nil,
        metrics: nil,
        trace_state: nil,
        trace_state_unknown_fields: nil
      )
        # Attributes
        @id = id || Tracing::Utils::TraceId.next_id
        @max_length = max_length || DEFAULT_MAX_LENGTH
        @parent_span_id = parent_span_id
        @sampled = sampled.nil? ? true : sampled

        # Tags
        @agent_sample_rate = agent_sample_rate
        @hostname = hostname
        @name = name
        @origin = origin
        @rate_limiter_rate = rate_limiter_rate
        @resource = resource
        @rule_sample_rate = rule_sample_rate
        @sample_rate = sample_rate
        @sampling_priority = sampling_priority
        @service = service
        @profiling_enabled = profiling_enabled
        @trace_state = trace_state
        @trace_state_unknown_fields = trace_state_unknown_fields

        # Generic tags
        set_tags(tags) if tags
        set_tags(metrics) if metrics

        # State
        @root_span = nil
        @active_span = nil
        @active_span_count = 0
        @events = events || Events.new
        @finished = false
        @spans = []
      end

      def full?
        @max_length > 0 && @active_span_count >= @max_length
      end

      def finished_span_count
        @spans.length
      end

      def finished?
        @finished == true
      end

      # Will this trace be flushed by the tracer transport?
      # This includes cases where the span is kept solely due to priority sampling.
      #
      # This is not the ultimate Datadog App sampling decision. Downstream systems
      # can decide to reject this trace, especially for cases where priority
      # sampling is set to AUTO_KEEP.
      #
      # @return [Boolean]
      def sampled?
        @sampled == true || priority_sampled?
      end

      # Has the priority sampling chosen to keep this span?
      # @return [Boolean]
      def priority_sampled?
        !@sampling_priority.nil? && @sampling_priority > 0
      end

      def keep!
        self.sampled = true
        self.sampling_priority = Sampling::Ext::Priority::USER_KEEP
        set_tag(Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER, Tracing::Sampling::Ext::Decision::MANUAL)
      end

      def reject!
        self.sampled = false
        self.sampling_priority = Sampling::Ext::Priority::USER_REJECT
        set_tag(Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER, Tracing::Sampling::Ext::Decision::MANUAL)
      end

      def name
        @name || (root_span && root_span.name)
      end

      def resource
        @resource || (root_span && root_span.resource)
      end

      # Returns true if the resource has been explicitly set
      #
      # @return [Boolean]
      def resource_override?
        !@resource.nil?
      end

      def service
        @service || (root_span && root_span.service)
      end

      def measure(
        op_name,
        events: nil,
        on_error: nil,
        resource: nil,
        service: nil,
        start_time: nil,
        tags: nil,
        type: nil,
        &block
      )
        # Don't allow more span measurements if the
        # trace is already completed. Prevents multiple
        # root spans with parent_span_id = 0.
        return yield(SpanOperation.new(op_name), TraceOperation.new) if finished? || full?

        # Create new span
        span_op = build_span(
          op_name,
          events: events,
          on_error: on_error,
          resource: resource,
          service: service,
          start_time: start_time,
          tags: tags,
          type: type
        )

        # Start span measurement
        span_op.measure { |s| yield(s, self) }
      end

      def build_span(
        op_name,
        events: nil,
        on_error: nil,
        resource: nil,
        service: nil,
        start_time: nil,
        tags: nil,
        type: nil
      )
        begin
          # Resolve span options:
          # Parent, service name, etc.
          # Add default options
          trace_id = @id
          parent = @active_span

          # Use active span's span ID if available. Otherwise, the parent span ID.
          # Necessary when this trace continues from another, e.g. distributed trace.
          parent_id = parent ? parent.id : @parent_span_id || 0

          # Build events
          events ||= SpanOperation::Events.new

          # Before start: activate the span, publish events.
          events.before_start.subscribe do |span_op|
            start_span(span_op)
          end

          # After finish: deactivate the span, record, publish events.
          events.after_finish.subscribe do |span, span_op|
            finish_span(span, span_op, parent)
          end

          # Build a new span operation
          SpanOperation.new(
            op_name,
            events: events,
            on_error: on_error,
            parent_id: parent_id,
            resource: resource || op_name,
            service: service,
            start_time: start_time,
            tags: tags,
            trace_id: trace_id,
            type: type
          )
        rescue StandardError => e
          Datadog.logger.debug { "Failed to build new span: #{e}" }

          # Return dummy span
          SpanOperation.new(op_name)
        end
      end

      # Returns a {TraceSegment} with all finished spans that can be flushed
      # at invocation time. All other **finished** spans are discarded.
      #
      # @yield [spans] spans that will be returned as part of the trace segment returned
      # @return [TraceSegment]
      def flush!
        finished = finished?

        # Copy out completed spans
        spans = @spans.dup
        @spans = []

        spans = yield(spans) if block_given?

        # Use them to build a trace
        build_trace(spans, !finished)
      end

      # Returns a set of trace headers used for continuing traces.
      # Used for propagation across execution contexts.
      # Data should reflect the active state of the trace.
      def to_digest
        # Resolve current span ID
        span_id = @active_span && @active_span.id
        span_id ||= @parent_span_id unless finished?

        TraceDigest.new(
          span_id: span_id,
          span_name: (@active_span && @active_span.name),
          span_resource: (@active_span && @active_span.resource),
          span_service: (@active_span && @active_span.service),
          span_type: (@active_span && @active_span.type),
          trace_distributed_tags: distributed_tags,
          trace_hostname: @hostname,
          trace_id: @id,
          trace_name: name,
          trace_origin: @origin,
          trace_process_id: Core::Environment::Identity.pid,
          trace_resource: resource,
          trace_runtime_id: Core::Environment::Identity.id,
          trace_sampling_priority: @sampling_priority,
          trace_service: service,
          trace_state: @trace_state,
          trace_state_unknown_fields: @trace_state_unknown_fields,
        ).freeze
      end

      # Returns a copy of this trace suitable for forks (w/o spans.)
      # Used for continuation of traces across forks.
      def fork_clone
        self.class.new(
          agent_sample_rate: @agent_sample_rate,
          events: (@events && @events.dup),
          hostname: (@hostname && @hostname.dup),
          id: @id,
          max_length: @max_length,
          name: (name && name.dup),
          origin: (@origin && @origin.dup),
          parent_span_id: (@active_span && @active_span.id) || @parent_span_id,
          rate_limiter_rate: @rate_limiter_rate,
          resource: (resource && resource.dup),
          rule_sample_rate: @rule_sample_rate,
          sample_rate: @sample_rate,
          sampled: @sampled,
          sampling_priority: @sampling_priority,
          service: (service && service.dup),
          trace_state: (@trace_state && @trace_state.dup),
          trace_state_unknown_fields: (@trace_state_unknown_fields && @trace_state_unknown_fields.dup),
          tags: meta.dup,
          metrics: metrics.dup
        )
      end

      # Callback behavior
      class Events
        include Tracing::Events

        attr_reader \
          :span_before_start,
          :span_finished,
          :trace_finished

        def initialize
          @span_before_start = SpanBeforeStart.new
          @span_finished = SpanFinished.new
          @trace_finished = TraceFinished.new
        end

        # Triggered before a span starts.
        class SpanBeforeStart < Tracing::Event
          def initialize
            super(:span_before_start)
          end
        end

        # Triggered when a span finishes, regardless of error.
        class SpanFinished < Tracing::Event
          def initialize
            super(:span_finished)
          end
        end

        # Triggered when the trace finishes, regardless of error.
        class TraceFinished < Tracing::Event
          def initialize
            super(:trace_finished)
            @deactivate_trace_subscribed = false
          end

          def deactivate_trace_subscribed?
            @deactivate_trace_subscribed
          end

          def subscribe_deactivate_trace(&block)
            @deactivate_trace_subscribed = true
            subscribe(&block)
          end
        end
      end

      private

      attr_reader \
        :events,
        :root_span

      def activate_span!(span_op)
        parent = @active_span

        span_op.send(:parent=, parent) unless parent.nil?

        @active_span = span_op

        set_root_span!(span_op) unless root_span
      end

      def deactivate_span!(span_op)
        # Set parent to closest unfinished ancestor span.
        # Prevents wrong span from being set as the active span
        # when spans finish out of order.
        span_op = span_op.send(:parent) while !span_op.nil? && span_op.finished?
        @active_span = span_op
      end

      def start_span(span_op)
        begin
          activate_span!(span_op)

          # Update active span count
          @active_span_count += 1

          # Publish :span_before_start event
          events.span_before_start.publish(span_op, self)
        rescue StandardError => e
          Datadog.logger.debug { "Error starting span on trace: #{e} Backtrace: #{e.backtrace.first(3)}" }
        end
      end

      def finish_span(span, span_op, parent)
        begin
          # Save finished span & root span
          @spans << span unless span.nil?

          # Deactivate the span, re-activate parent.
          deactivate_span!(span_op)

          # Set finished, to signal root span has completed.
          @finished = true if span_op == root_span

          # Update active span count
          @active_span_count -= 1

          # Publish :span_finished event
          events.span_finished.publish(span, self)

          # Publish :trace_finished event
          events.trace_finished.publish(self) if finished?
        rescue StandardError => e
          Datadog.logger.debug { "Error finishing span on trace: #{e} Backtrace: #{e.backtrace.first(3)}" }
        end
      end

      # Track the root span
      def set_root_span!(span)
        return if span.nil? || root_span

        @root_span = span
      end

      def build_trace(spans, partial = false)
        TraceSegment.new(
          spans,
          agent_sample_rate: @agent_sample_rate,
          hostname: @hostname,
          id: @id,
          lang: Core::Environment::Identity.lang,
          origin: @origin,
          process_id: Core::Environment::Identity.pid,
          rate_limiter_rate: @rate_limiter_rate,
          rule_sample_rate: @rule_sample_rate,
          runtime_id: Core::Environment::Identity.id,
          sample_rate: @sample_rate,
          sampling_priority: @sampling_priority,
          name: name,
          resource: resource,
          service: service,
          tags: meta,
          metrics: metrics,
          root_span_id: !partial ? root_span && root_span.id : nil,
          profiling_enabled: @profiling_enabled,
        )
      end

      # Returns tracer tags that will be propagated if this span's context
      # is exported through {.to_digest}.
      # @return [Hash] key value pairs of distributed tags
      def distributed_tags
        meta.select { |name, _| name.start_with?(Metadata::Ext::Distributed::TAGS_PREFIX) }
      end

      def reset
        @root_span = nil
        @active_span = nil
        @active_span_count = 0
        @finished = false
        @spans = []
      end
    end
  end
end
