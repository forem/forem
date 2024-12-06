require 'json-schema/attributes/limits/length'

module JSON
  class Schema
    class MinLengthAttribute < LengthLimitAttribute
      def self.limit_name
        'minLength'
      end

      def self.error_message(schema)
        "was not of a minimum string length of #{limit(schema)}"
      end
    end
  end
end
