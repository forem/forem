# frozen_string_literal: true

module Honeycomb
  # Parsing and propagation for W3C trace headers
  module W3CPropagation
    # Parse trace headers
    module UnmarshalTraceContext
      INVALID_TRACE_ID = "00000000000000000000000000000000".freeze
      INVALID_SPAN_ID = "0000000000000000".freeze

      def parse_rack_env(env)
        parse env["HTTP_TRACEPARENT"]
      end

      def parse(serialized_trace)
        unless serialized_trace.nil?
          version, payload = serialized_trace.split("-", 2)
          # version should be 2 hex characters
          if version =~ /^[A-Fa-f0-9]{2}$/
            trace_id, parent_span_id = parse_v1(payload)

            if !trace_id.nil? && !parent_span_id.nil?
              # return nil for dataset
              return [trace_id, parent_span_id, nil, nil]
            end
          end
        end
        [nil, nil, nil, nil]
      end

      def parse_v1(payload)
        trace_id, parent_span_id, trace_flags = payload.split("-", 3)

        # if trace_flags is nil, it means a field is missing
        if trace_flags.nil? || trace_id == INVALID_TRACE_ID || parent_span_id == INVALID_SPAN_ID
          return [nil, nil]
        end

        [trace_id, parent_span_id]
      end

      module_function :parse_rack_env, :parse, :parse_v1
      public :parse
    end

    # Serialize trace headers
    module MarshalTraceContext
      def to_trace_header
        # do not propagate malformed ids
        if trace.id =~ /^[A-Fa-f0-9]{32}$/ && id =~ /^[A-Fa-f0-9]{16}$/
          return "00-#{trace.id}-#{id}-01"
        end

        nil
      end

      def self.parse_faraday_env(_env, propagation_context)
        {
          "traceparent" => to_trace_header(propagation_context),
        }
      end

      def self.to_trace_header(propagation_context)
        trace_id = propagation_context.trace_id
        parent_id = propagation_context.parent_id
        # do not propagate malformed ids
        if trace_id =~ /^[A-Fa-f0-9]{32}$/ && parent_id =~ /^[A-Fa-f0-9]{16}$/
          return "00-#{trace_id}-#{parent_id}-01"
        end

        nil
      end
    end
  end
end
