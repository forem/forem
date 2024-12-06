require 'json-schema/attributes/divisibleby'

module JSON
  class Schema
    class MultipleOfAttribute < DivisibleByAttribute
      def self.keyword
        'multipleOf'
      end
    end
  end
end
