# frozen_string_literal: true

module Honeycomb
  # Parsing and propagation for AWS trace headers
  module AWSPropagation
    # Parse trace headers
    module UnmarshalTraceContext
      def parse(serialized_trace)
        unless serialized_trace.nil?
          split = serialized_trace.split(";")

          trace_id, parent_span_id, trace_fields = get_fields(split)

          parent_span_id = trace_id if parent_span_id.nil?

          trace_fields = nil if trace_fields.empty?

          if !trace_id.nil? && !parent_span_id.nil?
            # return nil for dataset
            return [trace_id, parent_span_id, trace_fields, nil]
          end
        end

        [nil, nil, nil, nil]
      end

      def get_fields(fields)
        trace_id, parent_span_id = nil
        trace_fields = {}
        fields.each do |entry|
          key, value = entry.split("=", 2)
          case key.downcase
          when "root"
            trace_id = value
          when "self"
            parent_span_id = value
          when "parent"
            parent_span_id = value if parent_span_id.nil?
          else
            trace_fields[key] = value unless key.empty?
          end
        end

        [trace_id, parent_span_id, trace_fields]
      end

      module_function :parse, :get_fields
      public :parse
    end

    # Serialize trace headers
    module MarshalTraceContext
      def to_trace_header
        context = [""]
        unless trace.fields.keys.nil?
          trace.fields.keys.each do |key|
            context.push("#{key}=#{trace.fields[key]}")
          end
        end

        data_to_propagate = [
          "Root=#{trace.id}",
          "Parent=#{id}",
        ]
        "#{data_to_propagate.join(';')}#{context.join(';')}"
      end

      def self.to_trace_header(propagation_context)
        context = [""]
        fields = propagation_context.trace_fields
        unless fields.keys.nil?
          fields.keys.each do |key|
            context.push("#{key}=#{fields[key]}")
          end
        end

        data_to_propagate = [
          "Root=#{propagation_context.trace_id}",
          "Parent=#{propagation_context.parent_id}",
        ]
        "#{data_to_propagate.join(';')}#{context.join(';')}"
      end
    end
  end
end
