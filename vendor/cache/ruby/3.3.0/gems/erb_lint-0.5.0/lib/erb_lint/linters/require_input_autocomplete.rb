# frozen_string_literal: true

require "better_html"
require "better_html/tree/tag"

module ERBLint
  module Linters
    class RequireInputAutocomplete < Linter
      include LinterRegistry

      HTML_INPUT_TYPES_REQUIRING_AUTOCOMPLETE = [
        "color",
        "date",
        "datetime-local",
        "email",
        "month",
        "number",
        "password",
        "range",
        "search",
        "tel",
        "text",
        "time",
        "url",
        "week",
      ].freeze

      FORM_HELPERS_REQUIRING_AUTOCOMPLETE = [
        :date_field_tag,
        :color_field_tag,
        :email_field_tag,
        :text_field_tag,
        :utf8_enforcer_tag,
        :month_field_tag,
        :number_field_tag,
        :password_field_tag,
        :search_field_tag,
        :telephone_field_tag,
        :time_field_tag,
        :url_field_tag,
        :week_field_tag,
      ].freeze

      def run(processed_source)
        parser = processed_source.parser

        find_html_input_tags(parser)
        find_rails_helper_input_tags(parser)
      end

      private

      def find_html_input_tags(parser)
        parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)

          autocomplete_attribute = tag.attributes["autocomplete"]
          type_attribute = tag.attributes["type"]

          next if !html_input_tag?(tag) || autocomplete_present?(autocomplete_attribute)
          next unless html_type_requires_autocomplete_attribute?(type_attribute)

          add_offense(
            tag_node.to_a[1].loc,
            "Input tag is missing an autocomplete attribute. If no "\
              "autocomplete behaviour is desired, use the value `off` or `nope`.",
            [autocomplete_attribute]
          )
        end
      end

      def autocomplete_present?(autocomplete_attribute)
        autocomplete_attribute.present? && autocomplete_attribute.value_node.present?
      end

      def html_input_tag?(tag)
        !tag.closing? && tag.name == "input"
      end

      def html_type_requires_autocomplete_attribute?(type_attribute)
        type_present = type_attribute.present? && type_attribute.value_node.present?
        type_present && HTML_INPUT_TYPES_REQUIRING_AUTOCOMPLETE.include?(type_attribute.value)
      end

      def find_rails_helper_input_tags(parser)
        parser.ast.descendants(:erb).each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          source = code_node.loc.source
          ruby_node = extract_ruby_node(source)
          send_node = ruby_node&.descendants(:send)&.first

          next if code_comment?(indicator_node) ||
            !ruby_node ||
            !input_helper?(send_node) ||
            source.include?("autocomplete")

          add_offense(
            erb_node.loc,
            "Input field helper is missing an autocomplete attribute. If no "\
              "autocomplete behaviour is desired, use the value `off` or `nope`.",
            [erb_node, send_node]
          )
        end
      end

      def input_helper?(send_node)
        FORM_HELPERS_REQUIRING_AUTOCOMPLETE.include?(send_node&.method_name)
      end

      def code_comment?(indicator_node)
        indicator_node&.loc&.source == "#"
      end

      def extract_ruby_node(source)
        BetterHtml::TestHelper::RubyNode.parse(source)
      rescue ::Parser::SyntaxError
        nil
      end
    end
  end
end
