require 'json-schema/attribute'
require 'json-schema/attributes/ref'

module JSON
  class Schema
    class ExtendsAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        schemas = current_schema.schema['extends']
        schemas = [schemas] if !schemas.is_a?(Array)
        schemas.each do |s|
          uri,schema = get_extended_uri_and_schema(s, current_schema, validator)
          if schema
            schema.validate(data, fragments, processor, options)
          elsif uri
            message = "The extended schema '#{uri.to_s}' cannot be found"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          else
            message = "The property '#{build_fragment(fragments)}' was not a valid schema"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end
        end
      end

      def self.get_extended_uri_and_schema(s, current_schema, validator)
        uri,schema = nil,nil

        if s.is_a?(Hash)
          uri = current_schema.uri
          if s['$ref']
            ref_uri,ref_schema = JSON::Schema::RefAttribute.get_referenced_uri_and_schema(s, current_schema, validator)
            if ref_schema
              if s.size == 1 # Check if anything else apart from $ref
                uri,schema = ref_uri,ref_schema
              else
                s = s.dup
                s.delete '$ref'
                s = ref_schema.schema.merge(s)
              end
            end
          end
          schema ||= JSON::Schema.new(s,uri,validator)
        end

        [uri,schema]
      end
    end
  end
end
