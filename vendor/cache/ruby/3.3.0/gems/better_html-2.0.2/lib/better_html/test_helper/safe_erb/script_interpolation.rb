# frozen_string_literal: true

require_relative "base"
require "better_html/test_helper/ruby_node"

module BetterHtml
  module TestHelper
    module SafeErb
      class ScriptInterpolation < Base
        def validate
          script_tags.each do |tag, content_node|
            if content_node.present? && (tag.attributes["type"]&.value || "text/javascript") == "text/javascript"
              validate_script(content_node)
            end
          end

          if @parser.template_language == :javascript
            @parser.nodes_with_type(:text).each do |node|
              validate_script(node)
            end
          end
        end

        private

        def validate_script(node)
          erb_nodes(node).each do |erb_node, indicator_node, code_node|
            next unless indicator_node.present?

            indicator = indicator_node.loc.source
            next if indicator == "#" || indicator == "%"

            source = code_node.loc.source

            ruby_node = begin
              RubyNode.parse(source)
            rescue ::Parser::SyntaxError
              nil
            end
            next unless ruby_node

            validate_script_interpolation(erb_node, ruby_node)
          end
        end

        def validate_script_interpolation(parent_node, ruby_node)
          method_calls = ruby_node.return_values.select(&:method_call?)

          if method_calls.empty?
            add_error(
              "erb interpolation in javascript tag must call '(...).to_json'",
              location: parent_node.loc,
            )
            return
          end

          method_calls.each do |call_node|
            if call_node.method_name?(:raw)
              call_node.arguments.each do |argument_node|
                validate_script_interpolation(parent_node, argument_node)
              end
            elsif call_node.method_name?(:html_safe)
              validate_script_interpolation(parent_node, call_node.receiver)
            elsif !@config.javascript_safe_method?(call_node.method_name)
              add_error(
                "erb interpolation in javascript tag must call '(...).to_json'",
                location: parent_node.loc,
              )
            end
          end
        end
      end
    end
  end
end
