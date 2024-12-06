require 'json-schema/attribute'

module JSON
  class Schema
    class LimitAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        schema = current_schema.schema
        return unless data.is_a?(acceptable_type) && invalid?(schema, value(data))

        property    = build_fragment(fragments)
        description = error_message(schema)
        message = format("The property '%s' %s", property, description)
        validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
      end

      def self.invalid?(schema, data)
        exclusive = exclusive?(schema)
        limit = limit(schema)

        if limit_name.start_with?('max')
          exclusive ? data >= limit : data > limit
        else
          exclusive ? data <= limit : data < limit
        end
      end

      def self.limit(schema)
        schema[limit_name]
      end

      def self.exclusive?(schema)
        false
      end

      def self.value(data)
        data
      end

      def self.acceptable_type
        raise NotImplementedError
      end

      def self.error_message(schema)
        raise NotImplementedError
      end

      def self.limit_name
        raise NotImplementedError
      end
    end
  end
end
