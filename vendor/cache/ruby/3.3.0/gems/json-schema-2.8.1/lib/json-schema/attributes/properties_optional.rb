require 'json-schema/attribute'

module JSON
  class Schema
    class PropertiesOptionalAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Hash)

        schema = current_schema.schema
        schema['properties'].each do |property, property_schema|
          property = property.to_s

          if !property_schema['optional'] && !data.key?(property)
            message = "The property '#{build_fragment(fragments)}' did not contain a required property of '#{property}'"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end

          if data.has_key?(property)
            expected_schema = JSON::Schema.new(property_schema, current_schema.uri, validator)
            expected_schema.validate(data[property], fragments + [property], processor, options)
          end
        end
      end
    end
  end
end
