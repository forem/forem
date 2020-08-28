module ProfileFields
  # This module defines a tiny DSL for declarative profile field seeders.
  module FieldDefinition
    extend ActiveSupport::Concern

    class_methods do
      def call
        new.add_fields
      end

      def group(name = nil)
        @group = ProfileFieldGroup.find_or_create_by(name: name)
        yield if block_given?
        @group = nil
      end

      def fields
        @fields ||= []
      end

      private

      def field(label, input_type, placeholder: nil, description: nil, group: @group)
        fields << {
          label: label,
          input_type: input_type,
          placeholder_text: placeholder,
          description: description,
          profile_field_group: group
        }.compact
      end
    end

    def add_fields
      self.class.fields.each { |field| ProfileField.create(field) }
    end
  end
end
