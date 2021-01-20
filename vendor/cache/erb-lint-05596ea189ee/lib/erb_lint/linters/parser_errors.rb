# frozen_string_literal: true

module ERBLint
  module Linters
    class ParserErrors < Linter
      include LinterRegistry

      def run(processed_source)
        processed_source.parser.parser_errors.each do |error|
          add_offense(
            error.loc,
            "#{error.message} (at #{error.loc.source})"
          )
        end
      end
    end
  end
end
