# frozen_string_literal: true

require_relative 'collector'
require_relative 'v1/app_event'
require_relative 'v1/telemetry_request'
require_relative 'v2/app_client_configuration_change'

module Datadog
  module Core
    module Telemetry
      # Class defining methods to construct a Telemetry event
      class Event
        include Telemetry::Collector

        API_VERSION = 'v1'

        attr_reader \
          :api_version

        def initialize
          @api_version = API_VERSION
        end

        # Forms a TelemetryRequest object based on the event request_type
        # @param request_type [String] the type of telemetry request to collect data for
        # @param seq_id [Integer] the ID of the request; incremented each time a telemetry request is sent to the API
        # @param data [Object] arbitrary object to be passed to the respective `request_type` handler
        def telemetry_request(request_type:, seq_id:, data: nil)
          Telemetry::V1::TelemetryRequest.new(
            api_version: @api_version,
            application: application,
            host: host,
            payload: payload(request_type, data),
            request_type: request_type,
            runtime_id: runtime_id,
            seq_id: seq_id,
            tracer_time: tracer_time,
          )
        end

        private

        def payload(request_type, data)
          case request_type
          when :'app-started'
            app_started
          when :'app-closing', :'app-heartbeat'
            {}
          when :'app-integrations-change'
            app_integrations_change
          when 'app-client-configuration-change'
            app_client_configuration_change(data)
          else
            raise ArgumentError, "Request type invalid, received request_type: #{@request_type}"
          end
        end

        def app_started
          Telemetry::V1::AppEvent.new(
            dependencies: dependencies,
            integrations: integrations,
            configuration: configurations,
            additional_payload: additional_payload
          )
        end

        def app_integrations_change
          Telemetry::V1::AppEvent.new(integrations: integrations)
        end

        # DEV: During the transition from V1 to V2, the backend accepts many V2
        # DEV: payloads through the V1 transport protocol.
        # DEV: The `app-client-configuration-change` payload is one of them.
        # DEV: Once V2 is fully implemented, `Telemetry::V2::AppClientConfigurationChange`
        # DEV: should be reusable without major modifications.
        def app_client_configuration_change(data)
          Telemetry::V2::AppClientConfigurationChange.new(data[:changes], origin: data[:origin])
        end
      end
    end
  end
end
