# frozen_string_literal: true

require_relative "base"

module BetterHtml
  module TestHelper
    module SafeErb
      class AllowedScriptType < Base
        VALID_JAVASCRIPT_TAG_TYPES = ["application/ld+json", "text/javascript", "text/template", "text/html", "module"]

        def validate
          script_tags.each do |tag, _|
            validate_type(tag)
          end
        end

        private

        def validate_type(tag)
          type_attribute = tag.attributes["type"]

          return unless type_attribute
          return if VALID_JAVASCRIPT_TAG_TYPES.include?(type_attribute.value)

          add_error(
            "#{type_attribute.value} is not a valid type, valid types are #{VALID_JAVASCRIPT_TAG_TYPES.join(", ")}",
            location: type_attribute.loc
          )
        end
      end
    end
  end
end
