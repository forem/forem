module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for additional payload or configuration object
        class Configuration
          ERROR_NIL_NAME_MESSAGE = ':name must not be nil'.freeze

          attr_reader \
            :name,
            :value

          # @param name [String] Configuration/additional payload attribute name
          # @param value [String, Integer, Boolean] Corresponding value
          def initialize(name:, value: nil)
            raise ArgumentError, ERROR_NIL_NAME_MESSAGE if name.nil?

            @name = name
            @value = value
          end
        end
      end
    end
  end
end
