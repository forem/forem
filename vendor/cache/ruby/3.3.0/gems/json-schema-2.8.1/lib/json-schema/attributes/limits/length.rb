require 'json-schema/attributes/limit'

module JSON
  class Schema
    class LengthLimitAttribute < LimitAttribute
      def self.acceptable_type
        String
      end

      def self.value(data)
        data.length
      end
    end
  end
end
