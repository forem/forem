# frozen_string_literal: true

module Datadog
  module Tracing
    module Distributed
      module Headers
        # DEV-2.0: This module only exists for backwards compatibility with the public API. It should be removed.
        # @deprecated use [Datadog::Tracing::Distributed::Datadog] and [Datadog::Tracing::Distributed::B3]
        # @public_api
        module Ext
          HTTP_HEADER_TRACE_ID = 'x-datadog-trace-id'
          HTTP_HEADER_PARENT_ID = 'x-datadog-parent-id'
          HTTP_HEADER_SAMPLING_PRIORITY = 'x-datadog-sampling-priority'
          HTTP_HEADER_ORIGIN = 'x-datadog-origin'
          # Distributed trace-level tags
          HTTP_HEADER_TAGS = 'x-datadog-tags'

          # B3 keys used for distributed tracing.
          # @see https://github.com/openzipkin/b3-propagation
          B3_HEADER_TRACE_ID = 'x-b3-traceid'
          B3_HEADER_SPAN_ID = 'x-b3-spanid'
          B3_HEADER_SAMPLED = 'x-b3-sampled'
          B3_HEADER_SINGLE = 'b3'

          # gRPC metadata keys for distributed tracing. https://github.com/grpc/grpc-go/blob/v1.10.x/Documentation/grpc-metadata.md
          GRPC_METADATA_TRACE_ID = 'x-datadog-trace-id'
          GRPC_METADATA_PARENT_ID = 'x-datadog-parent-id'
          GRPC_METADATA_SAMPLING_PRIORITY = 'x-datadog-sampling-priority'
          GRPC_METADATA_ORIGIN = 'x-datadog-origin'
        end
      end
    end
  end
end
