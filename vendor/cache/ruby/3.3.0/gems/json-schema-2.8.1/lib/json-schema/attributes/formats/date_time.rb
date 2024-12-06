require 'json-schema/attributes/format'

module JSON
  class Schema
    class DateTimeFormat < FormatAttribute
      REGEXP = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([\.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/

      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        # Timestamp in restricted ISO-8601 YYYY-MM-DDThh:mm:ssZ with optional decimal fraction of the second
        if data.is_a?(String)
          error_message = "The property '#{build_fragment(fragments)}' must be a date/time in the ISO-8601 format of YYYY-MM-DDThh:mm:ssZ or YYYY-MM-DDThh:mm:ss.ssZ"
          if (m = REGEXP.match(data))
            parts = data.split("T")

            begin
              Date.parse(parts[0])
            rescue ArgumentError => e
              raise e unless e.message == 'invalid date'
              validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors])
              return
            end

            validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors]) and return if m.length < 4
            validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors]) and return if m[1].to_i > 23
            validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors]) and return if m[2].to_i > 59
            validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors]) and return if m[3].to_i > 59
          else
            validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors])
          end
        end
      end
    end
  end
end
