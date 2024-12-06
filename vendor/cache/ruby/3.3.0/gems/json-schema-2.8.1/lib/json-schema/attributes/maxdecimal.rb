require 'json-schema/attribute'

module JSON
  class Schema
    class MaxDecimalAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Numeric)

        max_decimal_places = current_schema.schema['maxDecimal']
        s = data.to_s.split(".")[1]
        if s && s.length > max_decimal_places
          message = "The property '#{build_fragment(fragments)}' had more decimal places than the allowed #{max_decimal_places}"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        end
      end
    end
  end
end
