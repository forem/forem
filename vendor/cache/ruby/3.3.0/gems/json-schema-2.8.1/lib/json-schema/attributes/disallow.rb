require 'json-schema/attribute'

module JSON
  class Schema
    class DisallowAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless type = validator.attributes['type']
        type.validate(current_schema, data, fragments, processor, validator, options.merge(:disallow => true))
      end
    end
  end
end
