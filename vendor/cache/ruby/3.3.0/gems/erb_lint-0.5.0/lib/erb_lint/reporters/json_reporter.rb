# frozen_string_literal: true

require "json"

module ERBLint
  module Reporters
    class JsonReporter < Reporter
      def preview; end

      def show
        puts formatted_data
      end

      private

      def formatted_data
        {
          metadata: metadata,
          files: formatted_files,
          summary: summary,
        }.to_json
      end

      def metadata
        {
          erb_lint_version: ERBLint::VERSION,
          ruby_engine: RUBY_ENGINE,
          ruby_version: RUBY_VERSION,
          ruby_patchlevel: RUBY_PATCHLEVEL.to_s,
          ruby_platform: RUBY_PLATFORM,
        }
      end

      def summary
        {
          offenses: stats.found,
          inspected_files: stats.processed_files.size,
          corrected: stats.corrected,
        }
      end

      def formatted_files
        processed_files.map do |filename, offenses|
          {
            path: filename,
            offenses: formatted_offenses(offenses),
          }
        end
      end

      def formatted_offenses(offenses)
        offenses.map do |offense|
          format_offense(offense)
        end
      end

      def format_offense(offense)
        {
          linter: offense.simple_name,
          message: offense.message.to_s,
          location: {
            start_line: offense.line_number,
            start_column: offense.column,
            last_line: offense.last_line,
            last_column: offense.last_column,
            length: offense.length,
          },
        }
      end
    end
  end
end
