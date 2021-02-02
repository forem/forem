# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects trailing whitespace at the end of a line
    class TrailingWhitespace < Linter
      include LinterRegistry

      TRAILING_WHITESPACE = /([[:space:]]*)\Z/

      def run(processed_source)
        lines = processed_source.file_content.split("\n", -1)
        document_pos = 0
        lines.each do |line|
          document_pos += line.length + 1
          whitespace = line.match(TRAILING_WHITESPACE)&.captures&.first
          next unless whitespace && !whitespace.empty?

          add_offense(
            processed_source.to_source_range((document_pos - whitespace.length - 1)...(document_pos - 1)),
            "Extra whitespace detected at end of line."
          )
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, '')
        end
      end
    end
  end
end
