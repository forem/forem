# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module TestVisibility
      module Serializers
        class Span < Base
          CONTENT_FIELDS = [
            "trace_id", "span_id", "parent_id",
            "name", "resource", "service",
            "error", "start", "duration",
            "meta", "metrics",
            "type" => "span_type"
          ].freeze

          CONTENT_MAP_SIZE = calculate_content_map_size(CONTENT_FIELDS)

          REQUIRED_FIELDS = [
            "trace_id",
            "span_id",
            "error",
            "name",
            "resource",
            "start",
            "duration"
          ].freeze

          def content_fields
            CONTENT_FIELDS
          end

          def content_map_size
            CONTENT_MAP_SIZE
          end

          def type
            "span"
          end

          private

          def required_fields
            REQUIRED_FIELDS
          end
        end
      end
    end
  end
end
