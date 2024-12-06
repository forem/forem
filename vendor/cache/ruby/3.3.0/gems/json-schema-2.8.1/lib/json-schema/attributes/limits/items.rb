require 'json-schema/attributes/limit'

module JSON
  class Schema
    class ItemsLimitAttribute < LimitAttribute
      def self.acceptable_type
        Array
      end

      def self.value(data)
        data.length
      end
    end
  end
end
