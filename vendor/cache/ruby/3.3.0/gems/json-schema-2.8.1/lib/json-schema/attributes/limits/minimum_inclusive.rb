require 'json-schema/attributes/limits/minimum'

module JSON
  class Schema
    class MinimumInclusiveAttribute < MinimumAttribute
      def self.exclusive?(schema)
        schema['minimumCanEqual'] == false
      end
    end
  end
end
