# frozen_string_literal: true

require 'active_support/core_ext/hash/slice'
require 'json-schema'
require 'json'
require 'rswag/specs/extended_schema'

module Rswag
  module Specs
    class ResponseValidator
      def initialize(config = ::Rswag::Specs.config)
        @config = config
      end

      def validate!(metadata, response)
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

        validate_code!(metadata, response)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, swagger_doc, response.body)
      end

      private

      def validate_code!(metadata, response)
        expected = metadata[:response][:code].to_s
        if response.code != expected
          raise UnexpectedResponse,
            "Expected response code '#{response.code}' to match '#{expected}'\n" \
              "Response body: #{response.body}"
        end
      end

      def validate_headers!(metadata, headers)
        expected = (metadata[:response][:headers] || {}).keys
        expected.each do |name|
          raise UnexpectedResponse, "Expected response header #{name} to be present" if headers[name.to_s].nil?
        end
      end

      def validate_body!(metadata, swagger_doc, body)
        response_schema = metadata[:response][:schema]
        return if response_schema.nil?

        version = @config.get_swagger_doc_version(metadata[:swagger_doc])
        schemas = definitions_or_component_schemas(swagger_doc, version)

        validation_schema = response_schema
          .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
          .merge(schemas)

        errors = JSON::Validator.fully_validate(validation_schema, body)
        return unless errors.any?

        raise UnexpectedResponse,
              "Expected response body to match schema: #{errors[0]}\n" \
              "Response body: #{JSON.pretty_generate(JSON.parse(body))}"
      end

      def definitions_or_component_schemas(swagger_doc, version)
        if version.start_with?('2')
          swagger_doc.slice(:definitions)
        else # Openapi3
          if swagger_doc.key?(:definitions)
            ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: definitions is replaced in OpenAPI3! Rename to components/schemas (in swagger_helper.rb)')
            swagger_doc.slice(:definitions)
          else
            components = swagger_doc[:components] || {}
            { components: components }
          end
        end
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
