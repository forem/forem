require 'json-schema/attribute'

module JSON
  class Schema
    class AdditionalItemsAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Array)

        schema = current_schema.schema
        return unless schema['items'].is_a?(Array)

        case schema['additionalItems']
        when false
          if schema['items'].length < data.length
            message = "The property '#{build_fragment(fragments)}' contains additional array elements outside of the schema when none are allowed"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end
        when Hash
          additional_items_schema = JSON::Schema.new(schema['additionalItems'], current_schema.uri, validator)
          data.each_with_index do |item, i|
            next if i < schema['items'].length
            additional_items_schema.validate(item, fragments + [i.to_s], processor, options)
          end
        end
      end
    end
  end
end
