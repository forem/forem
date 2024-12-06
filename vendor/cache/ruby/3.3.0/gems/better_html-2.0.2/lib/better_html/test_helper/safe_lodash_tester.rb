# frozen_string_literal: true

require "better_html/test_helper/safety_error"
require "better_html/ast/iterator"
require "better_html/tree/tag"
require "better_html/parser"

module BetterHtml
  module TestHelper
    module SafeLodashTester
      SAFETY_TIPS = <<~EOF
        -----------

        The javascript snippets listed above do not appear to be escaped properly
        in their context. Here are some tips:

        Always use lodash's escape syntax inside a html tag:
          <a href="[%= value %]">
                   ^^^^

        Always use JSON.stringify() for html attributes which contain javascript, like 'onclick',
        or twine attributes like 'data-define', 'data-context', 'data-eval', 'data-bind', etc:
          <div onclick="[%= JSON.stringify(value) %]">
                            ^^^^^^^^^^^^^^

        Never use <script> tags inside lodash template.
          <script type="text/javascript">
          ^^^^^^^

        -----------
      EOF

      def assert_lodash_safety(data, **options)
        buffer = ::Parser::Source::Buffer.new(options[:filename] || "(buffer)")
        buffer.source = data
        tester = Tester.new(buffer, **options)

        message = +""
        tester.errors.each do |error|
          message << <<~EOL
            On line #{error.location.line}
            #{error.message}
            #{error.location.line_source_with_underline}\n
          EOL
        end

        message << SAFETY_TIPS

        assert_predicate(tester.errors, :empty?, message)
      end

      class Tester
        attr_reader :errors

        def initialize(buffer, config: BetterHtml.config)
          @buffer = buffer
          @config = config
          @errors = Errors.new
          @parser = BetterHtml::Parser.new(buffer, template_language: :lodash)
          validate!
        end

        def add_error(message, location:)
          @errors.add(SafetyError.new(message, location: location))
        end

        def validate!
          @parser.nodes_with_type(:tag).each do |tag_node|
            tag = Tree::Tag.from_node(tag_node)
            validate_tag_attributes(tag)
            validate_no_statements(tag_node)

            next unless tag.name == "script" && !tag.closing?

            add_error(
              "No script tags allowed nested in lodash templates",
              location: tag_node.loc
            )
          end

          @parser.nodes_with_type(:cdata, :comment).each do |node|
            validate_no_statements(node)
          end
        end

        def lodash_nodes(node)
          Enumerator.new do |yielder|
            next if node.nil?

            node.descendants(:lodash).each do |lodash_node|
              indicator_node, code_node = *lodash_node
              yielder.yield(lodash_node, indicator_node, code_node)
            end
          end
        end

        def validate_tag_attributes(tag)
          tag.attributes.each do |attribute|
            lodash_nodes(attribute.value_node).each do |lodash_node, indicator_node, _code_node|
              next if indicator_node.nil?

              if indicator_node.loc.source == "="
                validate_tag_expression(attribute, lodash_node)
              elsif indicator_node.loc.source == "!"
                add_error(
                  "lodash interpolation with '[%!' inside html attribute is never safe",
                  location: lodash_node.loc
                )
              end
            end
          end
        end

        def validate_tag_expression(attribute, lodash_node)
          _, code_node = *lodash_node
          source = code_node.loc.source.strip
          if @config.javascript_attribute_name?(attribute.name) && !@config.lodash_safe_javascript_expression?(source)
            add_error(
              "lodash interpolation in javascript attribute "\
                "`#{attribute.name}` must call `JSON.stringify(#{source})`",
              location: lodash_node.loc
            )
          end
        end

        def validate_no_statements(node)
          lodash_nodes(node).each do |lodash_node, indicator_node, _code_node|
            add_no_statement_error(lodash_node.loc) if indicator_node.nil?
          end
        end

        def add_no_statement_error(loc)
          add_error(
            "javascript statement not allowed here; did you mean '[%=' ?",
            location: loc
          )
        end
      end
    end
  end
end
