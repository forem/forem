require 'json-schema/attribute'

module JSON
  class Schema
    class PropertiesAttribute < Attribute
      def self.required?(schema, options)
        schema.fetch('required') { options[:strict] }
      end

      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Hash)

        schema = current_schema.schema
        schema['properties'].each do |property, property_schema|
          property = property.to_s

          if !data.key?(property) &&
              options[:insert_defaults] &&
              property_schema.has_key?('default') &&
              !property_schema['readonly']
            default = property_schema['default']
            data[property] = default.is_a?(Hash) ? default.clone : default
          end

          if required?(property_schema, options) && !data.has_key?(property)
            message = "The property '#{build_fragment(fragments)}' did not contain a required property of '#{property}'"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end

          if data.has_key?(property)
            expected_schema = JSON::Schema.new(property_schema, current_schema.uri, validator)
            expected_schema.validate(data[property], fragments + [property], processor, options)
          end
        end

        # When strict is true, ensure no undefined properties exist in the data
        return unless options[:strict] == true && !schema.key?('additionalProperties')

        diff = data.select do |k, v|
          k = k.to_s

          if schema.has_key?('patternProperties')
            match = false
            schema['patternProperties'].each do |property, property_schema|
              regexp = Regexp.new(property)
              if regexp.match(k)
                match = true
                break
              end
            end

            !schema['properties'].has_key?(k) && !match
          else
            !schema['properties'].has_key?(k)
          end
        end

        if diff.size > 0
          properties = diff.keys.join(', ')
          message = "The property '#{build_fragment(fragments)}' contained undefined properties: '#{properties}'"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        end
      end
    end
  end
end
