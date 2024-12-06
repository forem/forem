require 'json-schema/attribute'

module JSON
  class Schema
    class DependenciesAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Hash)

        current_schema.schema['dependencies'].each do |property, dependency_value|
          next unless data.has_key?(property.to_s)
          next unless accept_value?(dependency_value)

          case dependency_value
          when String
            validate_dependency(current_schema, data, property, dependency_value, fragments, processor, self, options)
          when Array
            dependency_value.each do |value|
              validate_dependency(current_schema, data, property, value, fragments, processor, self, options)
            end
          else
            schema = JSON::Schema.new(dependency_value, current_schema.uri, validator)
            schema.validate(data, fragments, processor, options)
          end
        end
      end

      def self.validate_dependency(schema, data, property, value, fragments, processor, attribute, options)
        return if data.key?(value.to_s)
        message = "The property '#{build_fragment(fragments)}' has a property '#{property}' that depends on a missing property '#{value}'"
        validation_error(processor, message, fragments, schema, attribute, options[:record_errors])
      end

      def self.accept_value?(value)
        value.is_a?(String) || value.is_a?(Array) || value.is_a?(Hash)
      end
    end
  end
end
