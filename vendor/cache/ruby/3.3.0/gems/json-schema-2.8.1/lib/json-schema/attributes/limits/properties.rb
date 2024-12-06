require 'json-schema/attributes/limit'

module JSON
  class Schema
    class PropertiesLimitAttribute < LimitAttribute
      def self.acceptable_type
        Hash
      end

      def self.value(data)
        data.size
      end
    end
  end
end
