require 'json-schema/attribute'

module JSON
  class Schema
    class RequiredAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Hash)

        schema = current_schema.schema
        defined_properties = schema['properties']

        schema['required'].each do |property, property_schema|
          next if data.has_key?(property.to_s)
          prop_defaults = options[:insert_defaults] &&
                          defined_properties &&
                          defined_properties[property] &&
                          !defined_properties[property]["default"].nil? &&
                          !defined_properties[property]["readonly"]

          if !prop_defaults
            message = "The property '#{build_fragment(fragments)}' did not contain a required property of '#{property}'"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end
        end
      end
    end
  end
end
