require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for integration object
        class Integration
          using Core::Utils::Hash::Refinement

          ERROR_NIL_ENABLED_MESSAGE = ':enabled must not be nil'.freeze
          ERROR_NIL_NAME_MESSAGE = ':name must not be nil'.freeze

          attr_reader \
            :auto_enabled,
            :compatible,
            :enabled,
            :error,
            :name,
            :version

          # @param enabled [Boolean] Whether integration is enabled at time of request
          # @param name [String] Integration name
          # @param auto_enabled [Boolean] If integration is not enabled by default, but by user choice
          # @param compatible [Boolean] If integration is available, but incompatible
          # @param error [String] Error message if integration fails to load
          # @param version [String] Integration version (if specified in app-started, it should be for other events too)
          def initialize(enabled:, name:, auto_enabled: nil, compatible: nil, error: nil, version: nil)
            validate(enabled: enabled, name: name)
            @auto_enabled = auto_enabled
            @compatible = compatible
            @enabled = enabled
            @error = error
            @name = name
            @version = version
          end

          def to_h
            hash = {
              auto_enabled: @auto_enabled,
              compatible: @compatible,
              enabled: @enabled,
              error: @error,
              name: @name,
              version: @version
            }
            hash.compact!
            hash
          end

          private

          # Validates all required arguments passed to the class on initialization are not nil
          #
          # @!visibility private
          def validate(enabled:, name:)
            raise ArgumentError, ERROR_NIL_ENABLED_MESSAGE if enabled.nil?
            raise ArgumentError, ERROR_NIL_NAME_MESSAGE if name.nil?
          end
        end
      end
    end
  end
end
