require 'json-schema/attributes/limit'

module JSON
  class Schema
    class NumericLimitAttribute < LimitAttribute
      def self.acceptable_type
        Numeric
      end

      def self.error_message(schema)
        exclusivity = exclusive?(schema) ? 'exclusively' : 'inclusively'
        format("did not have a %s value of %s, %s", limit_name, limit(schema), exclusivity)
      end
    end
  end
end
