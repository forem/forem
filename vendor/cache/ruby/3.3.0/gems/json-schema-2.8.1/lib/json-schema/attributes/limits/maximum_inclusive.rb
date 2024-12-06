require 'json-schema/attributes/limits/maximum'

module JSON
  class Schema
    class MaximumInclusiveAttribute < MaximumAttribute
      def self.exclusive?(schema)
        schema['maximumCanEqual'] == false
      end
    end
  end
end
