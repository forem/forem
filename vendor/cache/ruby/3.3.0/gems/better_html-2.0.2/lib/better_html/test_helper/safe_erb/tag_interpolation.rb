# frozen_string_literal: true

require_relative "base"
require "better_html/test_helper/ruby_node"

module BetterHtml
  module TestHelper
    module SafeErb
      class TagInterpolation < Base
        NO_HTML_TAGS = ["title", "textarea", "script", "style", "xmp", "iframe", "noembed", "noframes", "listing",
                        "plaintext",]

        def validate
          @parser.nodes_with_type(:tag).each do |tag_node|
            tag = Tree::Tag.from_node(tag_node)
            tag.attributes.each do |attribute|
              validate_attribute(attribute)
            end
          end

          @parser.nodes_with_type(:text).each do |node|
            validate_text_node(node) unless no_html_tag?(node)
          end
        end

        private

        def no_html_tag?(node)
          ast = @parser.ast.to_a
          index = ast.find_index(node)
          return unless (previous_node = ast[index - 1])
          return unless previous_node.type == :tag

          tag = BetterHtml::Tree::Tag.from_node(previous_node)
          NO_HTML_TAGS.include?(tag.name) && !tag.closing?
        end

        def validate_attribute(attribute)
          erb_nodes(attribute.value_node).each do |erb_node, indicator_node, code_node|
            next if indicator_node.nil?

            indicator = indicator_node.loc.source
            source = code_node.loc.source

            if indicator == "="
              ruby_node = begin
                RubyNode.parse(source)
              rescue ::Parser::SyntaxError
                nil
              end
              if ruby_node
                no_unsafe_calls(code_node, ruby_node)
                unless ruby_node.static_return_value?
                  handle_missing_safe_wrapper(code_node, ruby_node, attribute.name)
                end
              end
            elsif indicator == "=="
              add_error(
                "erb interpolation with '<%==' inside html attribute is never safe",
                location: erb_node.loc
              )
            end
          end
        end

        def validate_text_node(text_node)
          erb_nodes(text_node).each do |_erb_node, indicator_node, code_node|
            indicator = indicator_node&.loc&.source
            next if indicator == "#" || indicator == "%"

            source = code_node.loc.source

            ruby_node = begin
              RubyNode.parse(source)
            rescue ::Parser::SyntaxError
              nil
            end
            next unless ruby_node

            no_unsafe_calls(code_node, ruby_node)
            validate_ruby_helper(code_node, ruby_node)
          end
        end

        def validate_ruby_helper(parent_node, ruby_node)
          ruby_node.descendants(:send, :csend).each do |send_node|
            send_node.descendants(:hash).each do |hash_node|
              hash_node.child_nodes.select(&:pair?).each do |pair_node|
                validate_ruby_helper_hash_entry(parent_node, ruby_node, nil, *pair_node.children)
              end
            end
          end
        end

        def validate_ruby_helper_hash_entry(parent_node, ruby_node, key_prefix, key_node, value_node)
          return unless [:sym, :str].include?(key_node.type)

          key = [key_prefix, key_node.children.first.to_s].compact.join("-").dasherize
          case value_node.type
          when :dstr
            validate_ruby_helper_hash_value(parent_node, ruby_node, key, value_node)
          when :hash
            if key == "data"
              value_node.child_nodes.select(&:pair?).each do |pair_node|
                validate_ruby_helper_hash_entry(parent_node, ruby_node, key, *pair_node.children)
              end
            end
          end
        end

        def validate_ruby_helper_hash_value(parent_node, ruby_node, attr_name, hash_value)
          hash_value.child_nodes.select(&:begin?).each do |begin_node|
            validate_tag_interpolation(parent_node, begin_node, attr_name)
          end
        end

        def handle_missing_safe_wrapper(parent_node, ruby_node, attr_name)
          return unless @config.javascript_attribute_name?(attr_name)

          method_calls = ruby_node.return_values.select(&:method_call?)
          unsafe_calls = method_calls.select { |node| !@config.javascript_safe_method?(node.method_name) }
          if method_calls.empty?
            add_error(
              "erb interpolation in javascript attribute must be wrapped in safe helper such as '(...).to_json'",
              location: nested_location(parent_node, ruby_node)
            )
            true
          elsif unsafe_calls.any?
            unsafe_calls.each do |call_node|
              add_error(
                "erb interpolation in javascript attribute must be wrapped in safe helper such as '(...).to_json'",
                location: nested_location(parent_node, call_node)
              )
            end
            true
          end
        end

        def validate_tag_interpolation(parent_node, ruby_node, attr_name)
          return if ruby_node.static_return_value?
          return if handle_missing_safe_wrapper(parent_node, ruby_node, attr_name)

          ruby_node.return_values.each do |call_node|
            next if call_node.static_return_value?

            next unless @config.javascript_attribute_name?(attr_name) &&
              !@config.javascript_safe_method?(call_node.method_name)

            add_error(
              "erb interpolation in javascript attribute must be wrapped in safe helper such as '(...).to_json'",
              location: nested_location(parent_node, ruby_node)
            )
          end
        end

        def no_unsafe_calls(parent_node, ruby_node)
          ruby_node.descendants(:send, :csend).each do |call|
            if call.method_name?(:raw)
              add_error(
                "erb interpolation with '<%= raw(...) %>' in this context is never safe",
                location: nested_location(parent_node, ruby_node)
              )
            elsif call.method_name?(:html_safe)
              add_error(
                "erb interpolation with '<%= (...).html_safe %>' in this context is never safe",
                location: nested_location(parent_node, ruby_node)
              )
            end
          end
        end

        def nested_location(parent_node, ruby_node)
          Tokenizer::Location.new(
            parent_node.loc.source_buffer,
            parent_node.loc.begin_pos + ruby_node.loc.expression.begin_pos,
            parent_node.loc.begin_pos + ruby_node.loc.expression.end_pos
          )
        end
      end
    end
  end
end
