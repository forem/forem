require 'json-schema/attribute'

module JSON
  class Schema
    class FormatAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data_valid_for_type?(data, current_schema.schema['type'])
        format = current_schema.schema['format'].to_s
        validator = validator.formats[format]
        validator.validate(current_schema, data, fragments, processor, validator, options) unless validator.nil?
      end
    end
  end
end
