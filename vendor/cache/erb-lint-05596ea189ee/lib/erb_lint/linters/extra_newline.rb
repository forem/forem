# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects multiple blank lines
    class ExtraNewline < Linter
      include LinterRegistry

      EXTRA_NEWLINES = /(\n{3,})/m

      def run(processed_source)
        return unless (matches = processed_source.file_content.match(EXTRA_NEWLINES))

        matches.captures.each_index do |index|
          add_offense(
            processed_source
              .to_source_range((matches.begin(index) + 2)...matches.end(index)),
            "Extra blank line detected."
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
