require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for dependency object
        class Dependency
          using Core::Utils::Hash::Refinement

          ERROR_NIL_NAME_MESSAGE = ':name must not be nil'.freeze

          attr_reader \
            :hash,
            :name,
            :version

          # @param name [String] Module name
          # @param version [String] Version of resolved module
          # @param hash [String] Dependency hash, in case `version` is not available
          def initialize(name:, version: nil, hash: nil)
            raise ArgumentError, ERROR_NIL_NAME_MESSAGE if name.nil?
            raise ArgumentError, 'if both :version and :hash exist, use :version only' if version && hash

            @hash = hash
            @name = name
            @version = version
          end

          def to_h
            hash = {
              hash: @hash,
              name: @name,
              version: @version
            }
            hash.compact!
            hash
          end
        end
      end
    end
  end
end
