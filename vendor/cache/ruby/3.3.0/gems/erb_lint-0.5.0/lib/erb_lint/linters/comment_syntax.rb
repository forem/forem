# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects comment syntax that isn't valid ERB.
    class CommentSyntax < Linter
      include LinterRegistry

      def initialize(file_loader, config)
        super
      end

      def run(processed_source)
        file_content = processed_source.file_content
        return if file_content.empty?

        processed_source.ast.descendants(:erb).each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          next if code_node.nil?

          indicator_node_str = indicator_node&.deconstruct&.last
          next if indicator_node_str == "#"

          code_node_str = code_node.deconstruct.last
          next unless code_node_str.start_with?(" #")

          range = find_range(erb_node, code_node_str)
          source_range = processed_source.to_source_range(range)

          correct_erb_tag = indicator_node_str == "=" ? "<%#=" : "<%#"

          add_offense(
            source_range,
            <<~EOF.chomp
              Bad ERB comment syntax. Should be #{correct_erb_tag} without a space between.
              Leaving a space between ERB tags and the Ruby comment character can cause parser errors.
            EOF
          )
        end
      end

      def find_range(node, str)
        match = node.loc.source.match(Regexp.new(Regexp.quote(str.strip)))
        return unless match

        range_begin = match.begin(0) + node.loc.begin_pos
        range_end   = match.end(0) + node.loc.begin_pos
        (range_begin...range_end)
      end
    end
  end
end
