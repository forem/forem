require 'json-schema/attribute'

module JSON
  class Schema
    class AnyOfAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        # Create a hash to hold errors that are generated during validation
        errors = Hash.new { |hsh, k| hsh[k] = [] }
        valid = false

        original_data = data.is_a?(Hash) ? data.clone : data

        current_schema.schema['anyOf'].each_with_index do |element, schema_index|
          schema = JSON::Schema.new(element,current_schema.uri,validator)

          # We're going to add a little cruft here to try and maintain any validation errors that occur in the anyOf
          # We'll handle this by keeping an error count before and after validation, extracting those errors and pushing them onto a union error
          pre_validation_error_count = validation_errors(processor).count

          begin
            schema.validate(data,fragments,processor,options)
            valid = true
          rescue ValidationError
            # We don't care that these schemas don't validate - we only care that one validated
          end

          diff = validation_errors(processor).count - pre_validation_error_count
          valid = false if diff > 0
          while diff > 0
            diff = diff - 1
            errors["anyOf ##{schema_index}"].push(validation_errors(processor).pop)
          end

          break if valid

          data = original_data
        end

        if !valid
          message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} did not match one or more of the required schemas"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          validation_errors(processor).last.sub_errors = errors
        end
      end
    end
  end
end
