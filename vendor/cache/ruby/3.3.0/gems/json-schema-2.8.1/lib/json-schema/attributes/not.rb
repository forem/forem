require 'json-schema/attribute'

module JSON
  class Schema
    class NotAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        schema = JSON::Schema.new(current_schema.schema['not'],current_schema.uri,validator)
        failed = true
        errors_copy = processor.validation_errors.clone

        begin
          schema.validate(data,fragments,processor,options)
          # If we're recording errors, we don't throw an exception. Instead, check the errors array length
          if options[:record_errors] && errors_copy.length != processor.validation_errors.length
            processor.validation_errors.replace(errors_copy)
          else
            message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} matched the disallowed schema"
            failed = false
          end
        rescue ValidationError
          # Yay, we failed validation.
        end

        unless failed
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        end
      end
    end
  end
end
