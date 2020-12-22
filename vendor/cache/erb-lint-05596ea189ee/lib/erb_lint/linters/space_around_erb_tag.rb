# frozen_string_literal: true

module ERBLint
  module Linters
    # Enforce a single space after `<%` and before `%>` in the erb source.
    # This linter ignores opening erb tags (`<%`) that are followed by a newline,
    # and closing erb tags (`%>`) that are preceeded by a newline.
    class SpaceAroundErbTag < Linter
      include LinterRegistry

      START_SPACES = /\A([[:space:]]*)/m
      END_SPACES = /([[:space:]]*)\z/m

      def run(processed_source)
        processed_source.ast.descendants(:erb).each do |erb_node|
          indicator_node, ltrim, code_node, rtrim = *erb_node
          indicator = indicator_node&.loc&.source
          next if indicator == '#' || indicator == '%'
          code = code_node.children.first

          start_spaces = code.match(START_SPACES)&.captures&.first || ""
          if start_spaces.size != 1 && !start_spaces.include?("\n")
            add_offense(
              code_node.loc.resize(start_spaces.size),
              "Use 1 space after `<%#{indicator}#{ltrim&.loc&.source}` "\
              "instead of #{start_spaces.size} space#{'s' if start_spaces.size > 1}.",
              ' '
            )
          elsif start_spaces.count("\n") > 1
            lines = start_spaces.split("\n", -1)
            add_offense(
              code_node.loc.resize(start_spaces.size),
              "Use 1 newline after `<%#{indicator&.loc&.source}#{ltrim&.loc&.source}` "\
              "instead of #{start_spaces.count("\n")}.",
              "#{lines.first}\n#{lines.last}"
            )
          end

          end_spaces = code.match(END_SPACES)&.captures&.first || ""
          if end_spaces.size != 1 && !end_spaces.include?("\n")
            add_offense(
              code_node.loc.end.adjust(begin_pos: -end_spaces.size),
              "Use 1 space before `#{rtrim&.loc&.source}%>` "\
              "instead of #{end_spaces.size} space#{'s' if start_spaces.size > 1}.",
              ' '
            )
          elsif end_spaces.count("\n") > 1
            lines = end_spaces.split("\n", -1)
            add_offense(
              code_node.loc.end.adjust(begin_pos: -end_spaces.size),
              "Use 1 newline before `#{rtrim&.loc&.source}%>` "\
              "instead of #{end_spaces.count("\n")}.",
              "#{lines.first}\n#{lines.last}"
            )
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
