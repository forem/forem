# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module V2
        # Base request object for Telemetry V2.
        #
        # `#to_h` is the main API, which returns a Ruby
        # Hash that will be serialized as JSON.
        class Request
          # @param [String] request_type the Telemetry request type, which dictates how the Hash payload should be processed
          def initialize(request_type)
            @request_type = request_type
          end

          # Converts this request to a Hash that will
          # be serialized as JSON.
          # @return [Hash]
          def to_h
            {
              request_type: @request_type
            }
          end
        end
      end
    end
  end
end
