require 'json-schema/attribute'

module JSON
  class Schema
    class DivisibleByAttribute < Attribute
      def self.keyword
        'divisibleBy'
      end

      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Numeric)

        factor = current_schema.schema[keyword]

        if factor == 0 || factor == 0.0 || (BigDecimal(data.to_s) % BigDecimal(factor.to_s)).to_f != 0
          message = "The property '#{build_fragment(fragments)}' was not divisible by #{factor}"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        end
      end
    end
  end
end
