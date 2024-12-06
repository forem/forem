require 'json-schema/attributes/limits/numeric'

module JSON
  class Schema
    class MinimumAttribute < NumericLimitAttribute
      def self.limit_name
        'minimum'
      end

      def self.exclusive?(schema)
        schema['exclusiveMinimum']
      end
    end
  end
end
