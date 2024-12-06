require_relative 'event'
require_relative 'http/transport'
require_relative '../utils/sequence'
require_relative '../utils/forking'

module Datadog
  module Core
    module Telemetry
      # Class that emits telemetry events
      class Emitter
        attr_reader :http_transport

        extend Core::Utils::Forking

        # @param sequence [Datadog::Core::Utils::Sequence] Sequence object that stores and increments a counter
        # @param http_transport [Datadog::Core::Telemetry::Http::Transport] Transport object that can be used to send
        #   telemetry requests via the agent
        def initialize(http_transport: Datadog::Core::Telemetry::Http::Transport.new)
          @http_transport = http_transport
        end

        # Retrieves and emits a TelemetryRequest object based on the request type specified
        # @param request_type [String] the type of telemetry request to collect data for
        # @param data [Object] arbitrary object to be passed to the respective `request_type` handler
        def request(request_type, data: nil)
          begin
            request = Datadog::Core::Telemetry::Event.new.telemetry_request(
              request_type: request_type,
              seq_id: self.class.sequence.next,
              data: data,
            ).to_h
            @http_transport.request(request_type: request_type.to_s, payload: request.to_json)
          rescue StandardError => e
            Datadog.logger.debug("Unable to send telemetry request for event `#{request_type}`: #{e}")
            Telemetry::Http::InternalErrorResponse.new(e)
          end
        end

        # Initializes a Sequence object to track seq_id if not already initialized; else returns stored
        # Sequence object
        def self.sequence
          after_fork! { @sequence = Datadog::Core::Utils::Sequence.new(1) }
          @sequence ||= Datadog::Core::Utils::Sequence.new(1)
        end
      end
    end
  end
end
