# frozen_string_literal: true
require_relative "compact_reporter"

module ERBLint
  module Reporters
    class MultilineReporter < CompactReporter
      private

      def format_offense(filename, offense)
        <<~EOF

          #{offense.message}#{Rainbow(' (not autocorrected)').red if autocorrect}
          In file: #{filename}:#{offense.line_number}
        EOF
      end

      def footer
        puts
      end
    end
  end
end
