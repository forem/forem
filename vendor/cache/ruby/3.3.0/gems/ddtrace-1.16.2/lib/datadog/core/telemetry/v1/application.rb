require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for application environment object
        class Application
          using Core::Utils::Hash::Refinement

          ERROR_NIL_LANGUAGE_NAME_MESSAGE = ':language_name must not be nil'.freeze
          ERROR_NIL_LANGUAGE_VERSION_MESSAGE = ':language_version must not be nil'.freeze
          ERROR_NIL_SERVICE_NAME_MESSAGE = ':service_name must not be nil'.freeze
          ERROR_NIL_TRACER_VERSION_MESSAGE = ':tracer_version must not be nil'.freeze

          attr_reader \
            :env,
            :language_name,
            :language_version,
            :products,
            :runtime_name,
            :runtime_patches,
            :runtime_version,
            :service_name,
            :service_version,
            :tracer_version

          # @param env [String] Service's environment
          # @param language_name [String] 'ruby'
          # @param language_version [String] Version of language used
          # @param products [Telemetry::V1::Product] Contains information about specific products added to the environment
          # @param runtime_name [String] Runtime being used
          # @param runtime_patches [String] String of patches applied to the runtime
          # @param runtime_version [String] Runtime version; potentially the same as :language_version
          # @param service_name [String] Service’s name (DD_SERVICE)
          # @param service_version [String] Service’s version (DD_VERSION)
          # @param tracer_version [String] Version of the used tracer
          def initialize(
            language_name:, language_version:, service_name:, tracer_version:, env: nil, products: nil,
            runtime_name: nil, runtime_patches: nil, runtime_version: nil, service_version: nil
          )
            validate(
              language_name: language_name,
              language_version: language_version,
              service_name: service_name,
              tracer_version: tracer_version
            )
            @env = env
            @language_name = language_name
            @language_version = language_version
            @products = products
            @runtime_name = runtime_name
            @runtime_patches = runtime_patches
            @runtime_version = runtime_version
            @service_name = service_name
            @service_version = service_version
            @tracer_version = tracer_version
          end

          def to_h
            hash = {
              env: @env,
              language_name: @language_name,
              language_version: @language_version,
              products: @products.to_h,
              runtime_name: @runtime_name,
              runtime_patches: @runtime_patches,
              runtime_version: @runtime_version,
              service_name: @service_name,
              service_version: @service_version,
              tracer_version: @tracer_version
            }
            hash.compact!
            hash
          end

          private

          # Validates required arguments passed to the class on initialization are not nil
          #
          # @!visibility private
          def validate(language_name:, language_version:, service_name:, tracer_version:)
            raise ArgumentError, ERROR_NIL_LANGUAGE_NAME_MESSAGE if language_name.nil?
            raise ArgumentError, ERROR_NIL_LANGUAGE_VERSION_MESSAGE if language_version.nil?
            raise ArgumentError, ERROR_NIL_SERVICE_NAME_MESSAGE if service_name.nil?
            raise ArgumentError, ERROR_NIL_TRACER_VERSION_MESSAGE if tracer_version.nil?
          end
        end
      end
    end
  end
end
