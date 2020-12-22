# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects extra or missing whitespace in html tags.
    class SpaceInHtmlTag < Linter
      include LinterRegistry

      def run(processed_source)
        processed_source.ast.descendants(:tag).each do |tag_node|
          start_solidus, name, attributes, end_solidus = *tag_node

          next_loc = name&.loc&.begin_pos || attributes&.loc&.begin_pos ||
            end_solidus&.loc&.begin_pos || (tag_node.loc.end_pos - 1)
          if start_solidus
            no_space(processed_source, (tag_node.loc.begin_pos + 1)...start_solidus.loc.begin_pos)
            no_space(processed_source, start_solidus.loc.end_pos...next_loc)
          else
            no_space(processed_source, (tag_node.loc.begin_pos + 1)...next_loc)
          end

          if attributes
            single_space_or_newline(processed_source, name.loc.end_pos...attributes.loc.begin_pos) if name
            process_attributes(processed_source, attributes)
          end

          previous_loc = attributes&.loc&.end_pos || name&.loc&.end_pos ||
            start_solidus&.loc&.end_pos || (tag_node.loc.begin_pos + 1)
          if end_solidus
            single_space(processed_source, previous_loc...end_solidus.loc.begin_pos)
            no_space(processed_source, end_solidus.loc.end_pos...(tag_node.loc.end_pos - 1))
          else
            no_space(processed_source, previous_loc...(tag_node.loc.end_pos - 1))
          end
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context)
        end
      end

      private

      def no_space(processed_source, range)
        chars = processed_source.file_content[range]
        return if chars.empty?

        add_offense(
          processed_source.to_source_range(range),
          "Extra space detected where there should be no space.",
          ''
        )
      end

      def single_space_or_newline(processed_source, range)
        single_space(processed_source, range, accept_newline: true)
      end

      def single_space(processed_source, range, accept_newline: false)
        chars = processed_source.file_content[range]
        return if chars == ' '

        newlines = chars.include?("\n")
        expected = newlines && accept_newline ? "\n#{chars.split("\n", -1).last}" : ' '
        non_space = chars.match(/([^[[:space:]]])/m)

        if non_space && !non_space.captures.empty?
          add_offense(
            processed_source.to_source_range(range),
            "Non-whitespace character(s) detected: "\
              "#{non_space.captures.map(&:inspect).join(', ')}.",
            expected
          )
        elsif newlines && accept_newline
          if expected != chars
            add_offense(
              processed_source.to_source_range(range),
              "#{chars.empty? ? 'No' : 'Extra'} space detected where there should be "\
                "a single space or a single line break.",
              expected
            )
          end
        else
          add_offense(
            processed_source.to_source_range(range),
            "#{chars.empty? ? 'No' : 'Extra'} space detected where there should be a single space.",
            expected
          )
        end
      end

      def process_attributes(processed_source, attributes)
        attributes.children.each_with_index do |attribute, index|
          name, equal, value = *attribute
          no_space(processed_source, name.loc.end_pos...equal.loc.begin_pos) if name && equal
          no_space(processed_source, equal.loc.end_pos...value.loc.begin_pos) if equal && value

          next if index >= attributes.children.size - 1
          next_attribute = attributes.children[index + 1]

          single_space_or_newline(
            processed_source,
            attribute.loc.end_pos...next_attribute.loc.begin_pos
          )
        end
      end
    end
  end
end
