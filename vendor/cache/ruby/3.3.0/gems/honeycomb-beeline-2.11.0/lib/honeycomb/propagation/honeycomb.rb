# frozen_string_literal: true

require "base64"
require "json"
require "uri"

module Honeycomb
  # Parsing and propagation for honeycomb trace headers
  module HoneycombPropagation
    # Parse trace headers
    module UnmarshalTraceContext
      def parse_rack_env(env)
        parse env["HTTP_X_HONEYCOMB_TRACE"]
      end

      def parse(serialized_trace)
        unless serialized_trace.nil?
          version, payload = serialized_trace.split(";", 2)

          if version == "1"
            trace_id, parent_span_id, trace_fields, dataset = parse_v1(payload)

            if !trace_id.nil? && !parent_span_id.nil?
              return [trace_id, parent_span_id, trace_fields, dataset]
            end
          end
        end

        [nil, nil, nil, nil]
      end

      def parse_v1(payload)
        trace_id, parent_span_id, trace_fields, dataset = nil
        payload.split(",").each do |entry|
          key, value = entry.split("=", 2)
          case key.downcase
          when "dataset"
            dataset = URI.decode_www_form_component(value)
          when "trace_id"
            trace_id = value
          when "parent_id"
            parent_span_id = value
          when "context"
            Base64.decode64(value).tap do |json|
              begin
                trace_fields = JSON.parse json
              rescue JSON::ParserError
                trace_fields = {}
              end
            end
          end
        end

        [trace_id, parent_span_id, trace_fields, dataset]
      end

      module_function :parse_rack_env, :parse, :parse_v1
      public :parse_rack_env, :parse
    end

    # Serialize trace headers
    module MarshalTraceContext
      def to_trace_header
        context = Base64.urlsafe_encode64(JSON.generate(trace.fields)).strip
        encoded_dataset = URI.encode_www_form_component(builder.dataset)
        data_to_propogate = [
          "dataset=#{encoded_dataset}",
          "trace_id=#{trace.id}",
          "parent_id=#{id}",
          "context=#{context}",
        ]
        "1;#{data_to_propogate.join(',')}"
      end

      def self.parse_faraday_env(_env, propagation_context)
        {
          "X-Honeycomb-Trace" => to_trace_header(propagation_context),
        }
      end

      def self.to_trace_header(propagation_context)
        fields = propagation_context.trace_fields
        context = Base64.urlsafe_encode64(JSON.generate(fields)).strip
        dataset = propagation_context.dataset
        encoded_dataset = URI.encode_www_form_component(dataset)
        data_to_propogate = [
          "dataset=#{encoded_dataset}",
          "trace_id=#{propagation_context.trace_id}",
          "parent_id=#{propagation_context.parent_id}",
          "context=#{context}",
        ]
        "1;#{data_to_propogate.join(',')}"
      end
    end
  end
end
