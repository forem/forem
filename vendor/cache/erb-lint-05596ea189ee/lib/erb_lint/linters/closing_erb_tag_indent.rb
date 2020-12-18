# frozen_string_literal: true

module ERBLint
  module Linters
    # When `<%` isn't followed by a newline, ensure `%>` isn't preceeded by a newline.
    # When `%>` is preceeded by a newline, indent it at the same level as the corresponding `<%`.
    class ClosingErbTagIndent < Linter
      include LinterRegistry

      START_SPACES = /\A([[:space:]]*)/m
      END_SPACES = /([[:space:]]*)\z/m

      def run(processed_source)
        processed_source.ast.descendants(:erb).each do |erb_node|
          _, _, code_node, = *erb_node
          code = code_node.children.first

          start_spaces = code.match(START_SPACES)&.captures&.first || ""
          end_spaces = code.match(END_SPACES)&.captures&.first || ""

          start_with_newline = start_spaces.include?("\n")
          end_with_newline = end_spaces.include?("\n")

          if !start_with_newline && end_with_newline
            add_offense(
              code_node.loc.end.adjust(begin_pos: -end_spaces.size),
              "Remove newline before `%>` to match start of tag.",
              ' '
            )
          elsif start_with_newline && !end_with_newline
            add_offense(
              code_node.loc.end.adjust(begin_pos: -end_spaces.size),
              "Insert newline before `%>` to match start of tag.",
              "\n"
            )
          elsif start_with_newline && end_with_newline
            current_indent = end_spaces.split("\n", -1).last
            if erb_node.loc.column != current_indent.size
              add_offense(
                code_node.loc.end.adjust(begin_pos: -current_indent.size),
                "Indent `%>` on column #{erb_node.loc.column} to match start of tag.",
                ' ' * erb_node.loc.column
              )
            end
          end
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context)
        end
      end
    end
  end
end
