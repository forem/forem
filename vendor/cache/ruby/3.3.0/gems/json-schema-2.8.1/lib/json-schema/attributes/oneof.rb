require 'json-schema/attribute'

module JSON
  class Schema
    class OneOfAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        errors = Hash.new { |hsh, k| hsh[k] = [] }

        validation_error_count = 0
        one_of = current_schema.schema['oneOf']

        original_data = data.is_a?(Hash) ? data.clone : data
        success_data = nil

        valid = false

        one_of.each_with_index do |element, schema_index|
          schema = JSON::Schema.new(element,current_schema.uri,validator)
          pre_validation_error_count = validation_errors(processor).count
          begin
            schema.validate(data,fragments,processor,options)
            success_data = data.is_a?(Hash) ? data.clone : data
            valid = true
          rescue ValidationError
            valid = false
          end

          diff = validation_errors(processor).count - pre_validation_error_count
          valid = false if diff > 0
          validation_error_count += 1 if !valid
          while diff > 0
            diff = diff - 1
            errors["oneOf ##{schema_index}"].push(validation_errors(processor).pop)
          end
          data = original_data
        end



        if validation_error_count == one_of.length - 1
          data = success_data
          return
        end

        if validation_error_count == one_of.length
          message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} did not match any of the required schemas"
        else
          message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} matched more than one of the required schemas"
        end

        validation_error(processor, message, fragments, current_schema, self, options[:record_errors]) if message
        validation_errors(processor).last.sub_errors = errors if message
      end
    end
  end
end
