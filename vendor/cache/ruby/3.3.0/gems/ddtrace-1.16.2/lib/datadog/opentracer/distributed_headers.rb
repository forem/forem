require_relative '../tracing/distributed/datadog'
require_relative '../tracing/utils'

module Datadog
  module OpenTracer
    # DistributedHeaders provides easy access and validation to headers
    # @public_api
    class DistributedHeaders
      def initialize(carrier)
        @carrier = carrier
      end

      def valid?
        # Sampling priority is optional.
        !trace_id.nil? && !parent_id.nil?
      end

      def trace_id
        id Tracing::Distributed::Datadog::TRACE_ID_KEY
      end

      def parent_id
        id Tracing::Distributed::Datadog::PARENT_ID_KEY
      end

      def sampling_priority
        hdr = @carrier[Tracing::Distributed::Datadog::SAMPLING_PRIORITY_KEY]
        # It's important to make a difference between no header,
        # and a header defined to zero.
        return unless hdr

        value = hdr.to_i
        return if value < 0

        value
      end

      def origin
        hdr = @carrier[Tracing::Distributed::Datadog::ORIGIN_KEY]
        # Only return the value if it is not an empty string
        hdr if hdr != ''
      end

      private

      def id(header)
        value = @carrier[header].to_i
        return if value.zero? || value >= Datadog::Tracing::Utils::EXTERNAL_MAX_ID

        value < 0 ? value + 0x1_0000_0000_0000_0000 : value
      end
    end
  end
end
