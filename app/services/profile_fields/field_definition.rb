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

      def field(label, input_type, **attributes)
        attributes = attributes.reverse_merge(group: @group, display_area: "left_sidebar")
        fields << {
          label: label,
          input_type: input_type,
          placeholder_text: attributes[:placeholder],
          description: attributes[:description],
          profile_field_group: attributes[:group],
          display_area: attributes[:display_area],
          show_in_onboarding: attributes[:show_in_onboarding]
        }.compact
      end
    end

    def add_fields
      self.class.fields.each { |field| ProfileField.find_or_create_by(field) }
    end
  end
end
