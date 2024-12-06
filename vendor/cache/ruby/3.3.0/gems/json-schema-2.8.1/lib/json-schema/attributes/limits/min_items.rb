require 'json-schema/attributes/limits/items'

module JSON
  class Schema
    class MinItemsAttribute < ItemsLimitAttribute
      def self.limit_name
        'minItems'
      end

      def self.error_message(schema)
        "did not contain a minimum number of items #{limit(schema)}"
      end
    end
  end
end
