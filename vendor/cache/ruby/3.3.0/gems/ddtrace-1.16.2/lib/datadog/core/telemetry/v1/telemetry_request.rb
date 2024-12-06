require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for telemetry API request
        class TelemetryRequest
          using Core::Utils::Hash::Refinement

          ERROR_NIL_API_VERSION_MESSAGE = ':api_version must not be nil'.freeze
          ERROR_NIL_APPLICATION_MESSAGE = ':application must not be nil'.freeze
          ERROR_NIL_HOST_MESSAGE = ':host must not be nil'.freeze
          ERROR_NIL_PAYLOAD_MESSAGE = ':payload must not be nil'.freeze
          ERROR_NIL_REQUEST_TYPE_MESSAGE = ':request_type must not be nil'.freeze
          ERROR_NIL_RUNTIME_ID_MESSAGE = ':runtime_id must not be nil'.freeze
          ERROR_NIL_SEQ_ID_MESSAGE = ':seq_id must not be nil'.freeze
          ERROR_NIL_TRACER_TIME_MESSAGE = ':tracer_time must not be nil'.freeze

          attr_reader \
            :api_version,
            :application,
            :debug,
            :host,
            :payload,
            :request_type,
            :runtime_id,
            :seq_id,
            :session_id,
            :tracer_time

          # @param api_version [String] Requested API version, `v1`
          # @param application [Telemetry::V1::Application] Object that contains information about the environment of the
          #   application
          # @param host [Telemetry::V1::Host] Object that holds host related information
          # @param payload [Telemetry::V1::AppEvent] The payload of the request, type impacted by :request_type
          # @param request_type [String] Requested API function impacting the Payload type, `app-started`
          # @param runtime_id [String] V4 UUID that represents a tracer session
          # @param seq_id [Integer] Counter that should be auto incremented every time an API call is being made
          # @param tracer_time [Integer] Unix timestamp (in seconds) of when the message is being sent
          # @param debug [Boolean] Flag that enables payload debug mode
          # @param session_id [String] V4 UUID that represents the session of the top level tracer process, often same\
          #   as runtime_id
          def initialize(
            api_version:, application:, host:, payload:, request_type:, runtime_id:, seq_id:, tracer_time:,
            debug: nil, session_id: nil
          )
            validate(
              api_version: api_version,
              application: application,
              host: host,
              payload: payload,
              request_type: request_type,
              runtime_id: runtime_id,
              seq_id: seq_id,
              tracer_time: tracer_time
            )
            @api_version = api_version
            @application = application
            @debug = debug
            @host = host
            @payload = payload
            @request_type = request_type
            @runtime_id = runtime_id
            @seq_id = seq_id
            @session_id = session_id
            @tracer_time = tracer_time
          end

          def to_h
            hash = {
              api_version: @api_version,
              application: @application.to_h,
              debug: @debug,
              host: @host.to_h,
              payload: @payload.to_h,
              request_type: @request_type,
              runtime_id: @runtime_id,
              seq_id: @seq_id,
              session_id: @session_id,
              tracer_time: @tracer_time
            }
            hash.compact!
            hash
          end

          private

          # Validates all required arguments passed to the class on initialization are not nil
          #
          # @!visibility private
          def validate(api_version:, application:, host:, payload:, request_type:, runtime_id:, seq_id:, tracer_time:)
            raise ArgumentError, ERROR_NIL_API_VERSION_MESSAGE if api_version.nil?
            raise ArgumentError, ERROR_NIL_APPLICATION_MESSAGE if application.nil?
            raise ArgumentError, ERROR_NIL_HOST_MESSAGE if host.nil?
            raise ArgumentError, ERROR_NIL_PAYLOAD_MESSAGE if payload.nil?
            raise ArgumentError, ERROR_NIL_REQUEST_TYPE_MESSAGE if request_type.nil?
            raise ArgumentError, ERROR_NIL_RUNTIME_ID_MESSAGE if runtime_id.nil?
            raise ArgumentError, ERROR_NIL_SEQ_ID_MESSAGE if seq_id.nil?
            raise ArgumentError, ERROR_NIL_TRACER_TIME_MESSAGE if tracer_time.nil?
          end
        end
      end
    end
  end
end
