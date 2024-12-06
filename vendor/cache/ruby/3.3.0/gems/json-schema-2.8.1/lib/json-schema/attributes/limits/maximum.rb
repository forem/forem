require 'json-schema/attributes/limits/numeric'

module JSON
  class Schema
    class MaximumAttribute < NumericLimitAttribute
      def self.limit_name
        'maximum'
      end

      def self.exclusive?(schema)
        schema['exclusiveMaximum']
      end
    end
  end
end
