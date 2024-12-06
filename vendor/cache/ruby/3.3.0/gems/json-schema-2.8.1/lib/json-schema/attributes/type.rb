require 'json-schema/attribute'

module JSON
  class Schema
    class TypeAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        union = true
        if options[:disallow]
          types = current_schema.schema['disallow']
        else
          types = current_schema.schema['type']
        end

        if !types.is_a?(Array)
          types = [types]
          union = false
        end
        valid = false

        # Create a hash to hold errors that are generated during union validation
        union_errors = Hash.new { |hsh, k| hsh[k] = [] }

        types.each_with_index do |type, type_index|
          if type.is_a?(String)
            valid = data_valid_for_type?(data, type)
          elsif type.is_a?(Hash) && union
            # Validate as a schema
            schema = JSON::Schema.new(type,current_schema.uri,validator)

            # We're going to add a little cruft here to try and maintain any validation errors that occur in this union type
            # We'll handle this by keeping an error count before and after validation, extracting those errors and pushing them onto a union error
            pre_validation_error_count = validation_errors(processor).count

            begin
              schema.validate(data,fragments,processor,options.merge(:disallow => false))
              valid = true
            rescue ValidationError
              # We don't care that these schemas don't validate - we only care that one validated
            end

            diff = validation_errors(processor).count - pre_validation_error_count
            valid = false if diff > 0
            while diff > 0
              diff = diff - 1
              union_errors["type ##{type_index}"].push(validation_errors(processor).pop)
            end
          end

          break if valid
        end

        if options[:disallow]
          return if !valid
          message = "The property '#{build_fragment(fragments)}' matched one or more of the following types: #{list_types(types)}"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
        elsif !valid
          if union
            message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} did not match one or more of the following types: #{list_types(types)}"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
            validation_errors(processor).last.sub_errors = union_errors
          else
            message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} did not match the following type: #{list_types(types)}"
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          end
        end
      end

      def self.list_types(types)
        types.map { |type| type.is_a?(String) ? type : '(schema)' }.join(', ')
      end
    end
  end
end
