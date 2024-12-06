# frozen_string_literal: true

require_relative 'request'

module Datadog
  module Core
    module Telemetry
      module V2
        # Telemetry 'app-client-configuration-change' event.
        # This request should contain client library configuration that have changes since the app-started event.
        class AppClientConfigurationChange < Request
          def initialize(configuration_changes, origin: 'unknown')
            super('app-client-configuration-change')

            @configuration_changes = configuration_changes
            @origin = origin
          end

          # @see [Request#to_h]
          def to_h
            super.merge(payload: payload)
          end

          private

          def payload
            {
              configuration: @configuration_changes.map do |name, value|
                {
                  name: name,
                  value: value,
                  origin: @origin,
                }
              end
            }
          end
        end
      end
    end
  end
end
