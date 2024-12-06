# frozen_string_literal: true

require "better_html"
require "better_html/tree/tag"

module ERBLint
  module Linters
    # Allow inline script tags in ERB that have a nonce attribute.
    # This only validates inline <script> tags, as well as rails helpers like javascript_tag.
    class RequireScriptNonce < Linter
      include LinterRegistry

      def run(processed_source)
        parser = processed_source.parser

        find_html_script_tags(parser)
        find_rails_helper_script_tags(parser)
      end

      private

      def find_html_script_tags(parser)
        parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          nonce_attribute = tag.attributes["nonce"]

          next if !html_javascript_tag?(tag) || nonce_present?(nonce_attribute)

          add_offense(
            tag_node.to_a[1].loc,
            "Missing a nonce attribute. Use request.content_security_policy_nonce",
            [nonce_attribute]
          )
        end
      end

      def nonce_present?(nonce_attribute)
        nonce_attribute.present? && nonce_attribute.value_node.present?
      end

      def html_javascript_tag?(tag)
        !tag.closing? &&
          (tag.name == "script" && !html_javascript_type_attribute?(tag))
      end

      def html_javascript_type_attribute?(tag)
        type_attribute = tag.attributes["type"]

        type_attribute &&
          type_attribute.value_node.present? &&
          type_attribute.value_node.to_a[1] != "text/javascript" &&
          type_attribute.value_node.to_a[1] != "application/javascript"
      end

      def find_rails_helper_script_tags(parser)
        parser.ast.descendants(:erb).each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          source = code_node.loc.source
          ruby_node = extract_ruby_node(source)
          send_node = ruby_node&.descendants(:send)&.first

          next if code_comment?(indicator_node) ||
            !ruby_node ||
            !tag_helper?(send_node) ||
            source.include?("nonce")

          add_offense(
            erb_node.loc,
            "Missing a nonce attribute. Use nonce: true",
            [erb_node, send_node]
          )
        end
      end

      def tag_helper?(send_node)
        send_node&.method_name?(:javascript_tag) ||
          send_node&.method_name?(:javascript_include_tag) ||
          send_node&.method_name?(:javascript_pack_tag)
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
