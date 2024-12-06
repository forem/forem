# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes payload for telemetry V1 API app-integrations-change event
        class AppEvent
          attr_reader \
            :additional_payload,
            :configuration,
            :dependencies,
            :integrations

          # @param additional_payload [Array<Telemetry::V1::Configuration>] List of Additional payload to track (any key
          #   value not mentioned and doesn't fit under a metric)
          # @param configuration [Array<Telemetry::V1::Configuration>] List of Tracer related configuration data
          # @param dependencies [Array<Telemetry::V1::Dependency>] List of all loaded modules requested by the app
          # @param integrations [Array<Telemetry::V1::Integration>] List of integrations that are available within the app
          #   and applicable to be traced
          def initialize(additional_payload: nil, configuration: nil, dependencies: nil, integrations: nil)
            @additional_payload = additional_payload
            @configuration = configuration
            @dependencies = dependencies
            @integrations = integrations
          end

          def to_h
            {}.tap do |hash|
              hash[:additional_payload] = map_hash(@additional_payload) if @additional_payload
              hash[:configuration] = map_hash(@configuration) if @configuration
              hash[:dependencies] = map_array(@dependencies) if @dependencies
              hash[:integrations] = map_array(@integrations) if @integrations
            end
          end

          private

          def map_hash(hash)
            hash.map do |k, v|
              { name: k.to_s, value: v }
            end
          end

          def map_array(arr)
            arr.map(&:to_h)
          end
        end
      end
    end
  end
end
