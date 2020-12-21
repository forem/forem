# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'

module ERBLint
  module Linters
    # Checks for deprecated classes in the start tags of HTML elements.
    class DeprecatedClasses < Linter
      include LinterRegistry

      class RuleSet
        include SmartProperties
        property :suggestion, accepts: String, default: ''
        property :deprecated, accepts: LinterConfig.array_of?(String), default: -> { [] }
      end

      class ConfigSchema < LinterConfig
        property :rule_set,
          default: -> { [] },
          accepts: array_of?(RuleSet),
          converts: to_array_of(RuleSet)
        property :addendum, accepts: String
      end
      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        super
        @addendum = @config.addendum
      end

      def run(processed_source)
        process_nested_offenses(
          source: processed_source,
          offset: 0,
          parent_source: processed_source,
        )
      end

      private

      def process_nested_offenses(source:, offset:, parent_source:)
        class_name_with_loc(source).each do |class_name, loc|
          range = parent_source.to_source_range(loc).offset(offset)
          generate_offenses(class_name, range)
        end
        text_tags_content(source).each do |content_node|
          sub_source = ProcessedSource.new(source.filename, content_node.loc.source)
          process_nested_offenses(
            source: sub_source,
            offset: offset + content_node.loc.begin_pos,
            parent_source: parent_source
          )
        end
      end

      def class_name_with_loc(processed_source)
        Enumerator.new do |yielder|
          tags(processed_source).each do |tag|
            class_value = tag.attributes['class']&.value
            next unless class_value
            class_value.split(' ').each do |class_name|
              yielder.yield(class_name, tag.loc)
            end
          end
        end
      end

      def text_tags_content(processed_source)
        Enumerator.new do |yielder|
          script_tags(processed_source)
            .select { |tag| tag.attributes['type']&.value == 'text/html' }
            .each do |tag|
              index = processed_source.ast.to_a.find_index(tag.node)
              next_node = processed_source.ast.to_a[index + 1]

              yielder.yield(next_node) if next_node.type == :text
            end
        end
      end

      def script_tags(processed_source)
        tags(processed_source).select { |tag| tag.name == 'script' }
      end

      def tags(processed_source)
        tag_nodes(processed_source).map { |tag_node| BetterHtml::Tree::Tag.from_node(tag_node) }
      end

      def tag_nodes(processed_source)
        processed_source.parser.nodes_with_type(:tag)
      end

      def generate_offenses(class_name, range)
        violated_rules(class_name).each do |violated_rule|
          suggestion = " #{violated_rule[:suggestion]}".rstrip
          message = "Deprecated class `%s` detected matching the pattern `%s`.%s #{@addendum}".strip

          add_offense(
            range,
            format(message, class_name, violated_rule[:class_expr], suggestion)
          )
        end
      end

      def violated_rules(class_name)
        [].tap do |result|
          @config.rule_set.each do |rule|
            rule.deprecated.each do |deprecated|
              next unless /\A#{deprecated}\z/ =~ class_name

              result << {
                suggestion: rule.suggestion,
                class_expr: deprecated,
              }
            end
          end
        end
      end
    end
  end
end
