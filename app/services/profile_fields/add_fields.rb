module ProfileFields
  class AddFields
    class << self
      def call
        new.add_fields
      end

      def fields
        @fields ||= []
      end

      private

      def field(label, input_type, placeholder_text)
        fields << {
          label: label,
          input_type: input_type,
          placeholder_text: placeholder_text
        }
      end
    end

    def add_fields
      self.class.fields.each { |field| ProfileField.create(field) }
    end
  end
end
