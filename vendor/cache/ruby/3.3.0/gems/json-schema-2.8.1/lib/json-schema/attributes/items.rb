require 'json-schema/attribute'

module JSON
  class Schema
    class ItemsAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(Array)

        items = current_schema.schema['items']
        case items
        when Hash
          schema = JSON::Schema.new(items, current_schema.uri, validator)
          data.each_with_index do |item, i|
            schema.validate(item, fragments + [i.to_s], processor, options)
          end

        when Array
          items.each_with_index do |item_schema, i|
            break if i >= data.length
            schema = JSON::Schema.new(item_schema, current_schema.uri, validator)
            schema.validate(data[i], fragments + [i.to_s], processor, options)
          end
        end
      end
    end
  end
end
