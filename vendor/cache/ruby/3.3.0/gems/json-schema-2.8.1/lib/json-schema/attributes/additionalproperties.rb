require 'json-schema/attribute'
require 'json-schema/attributes/extends'

module JSON
  class Schema
    class AdditionalPropertiesAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        schema = current_schema.schema
        return unless data.is_a?(Hash) && (schema['type'].nil? || schema['type'] == 'object')

        extra_properties = remove_valid_properties(data.keys, current_schema, validator)

        addprop = schema['additionalProperties']
        if addprop.is_a?(Hash)
          matching_properties = extra_properties # & addprop.keys
          matching_properties.each do |key|
            additional_property_schema = JSON::Schema.new(addprop, current_schema.uri, validator)
            additional_property_schema.validate(data[key], fragments + [key], processor, options)
          end
          extra_properties -= matching_properties
        end

        if extra_properties.any? && (addprop == false || (addprop.is_a?(Hash) && !addprop.empty?))
          message = "The property '#{build_fragment(fragments)}' contains additional properties #{extra_properties.inspect} outside of the schema when none are allowed"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        end
      end

      def self.remove_valid_properties(extra_properties, current_schema, validator)
        schema = current_schema.schema

        if schema['properties']
          extra_properties = extra_properties - schema['properties'].keys
        end

        if schema['patternProperties']
          schema['patternProperties'].each_key do |key|
            regexp = Regexp.new(key)
            extra_properties.reject! { |prop| regexp.match(prop) }
          end
        end

        if extended_schemas = schema['extends']
          extended_schemas = [extended_schemas] unless extended_schemas.is_a?(Array)
          extended_schemas.each do |schema_value|
            _, extended_schema = JSON::Schema::ExtendsAttribute.get_extended_uri_and_schema(schema_value, current_schema, validator)
            if extended_schema
              extra_properties = remove_valid_properties(extra_properties, extended_schema, validator)
            end
          end
        end

        extra_properties
      end

    end
  end
end
