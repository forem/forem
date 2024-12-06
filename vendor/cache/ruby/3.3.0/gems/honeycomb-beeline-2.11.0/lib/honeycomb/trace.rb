# frozen_string_literal: true

require "forwardable"
require "securerandom"
require "honeycomb/span"
require "honeycomb/propagation"
require "honeycomb/rollup_fields"

module Honeycomb
  # Represents a Honeycomb trace, which groups spans together
  class Trace
    include RollupFields
    extend Forwardable

    def_delegators :@root_span, :send

    attr_reader :id, :fields, :root_span

    def initialize(builder:, context:, serialized_trace: nil, **options)
      trace_id, parent_span_id, trace_fields, dataset =
        internal_parse(context: context, serialized_trace: serialized_trace, **options)

      # if dataset is not nil,
      # set trace's builder.dataset = dataset from trace header
      if context.classic?
        dataset && builder.dataset = dataset
      end

      @id = trace_id || generate_trace_id
      @fields = trace_fields || {}
      @root_span = Span.new(trace: self,
                            parent_id: parent_span_id,
                            is_root: true,
                            builder: builder,
                            context: context,
                            **options)
    end

    def add_field(key, value)
      @fields[key] = value
    end

    private

    INVALID_TRACE_ID = ("00" * 16)

    def generate_trace_id
      loop do
        id = SecureRandom.hex(16)
        return id unless id == INVALID_TRACE_ID
      end
    end

    def internal_parse(context:, serialized_trace: nil, parser_hook: nil, **_options)
      # previously we passed in the header directly as a string for us to parse
      # now we get passed the rack env to use as an argument to the provided
      # parser_hook. This preserves the current behaviour and allows us to
      # move forward with the new behaviour without breaking changes
      if serialized_trace.is_a?(Hash) && parser_hook
        parser_hook.call(serialized_trace)
      elsif context.classic?
        HoneycombPropagation::UnmarshalTraceContext.parse serialized_trace
      else
        HoneycombModernPropagation::UnmarshalTraceContext.parse serialized_trace
      end
    end
  end
end
