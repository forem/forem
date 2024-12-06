# frozen_string_literal: true

module ERBLint
  module Reporters
    class CompactReporter < Reporter
      def preview
        puts "#{linting} #{stats.files} files with #{linters}..."
      end

      def show
        processed_files.each do |filename, offenses|
          offenses.each do |offense|
            puts format_offense(filename, offense)
          end
        end

        footer
        summary
      end

      private

      def linting
        "Linting" + (autocorrect ? " and autocorrecting" : "")
      end

      def linters
        "#{stats.linters} linters" + (autocorrect ? " (#{stats.autocorrectable_linters} autocorrectable)" : "")
      end

      def format_offense(filename, offense)
        [
          "#{filename}:",
          "#{offense.line_number}:",
          "#{offense.column}: ",
          offense.message.to_s,
        ].join
      end

      def footer; end

      def summary
        if stats.corrected > 0
          report_corrected_offenses
        elsif stats.ignored > 0 || stats.found > 0
          if stats.ignored > 0
            warn(Rainbow("#{stats.ignored} error(s) were ignored in ERB files").yellow)
          end

          if stats.found > 0
            warn(Rainbow("#{stats.found} error(s) were found in ERB files").red)
          end
        else
          puts Rainbow("No errors were found in ERB files").green
        end
      end

      def report_corrected_offenses
        corrected_found_diff = stats.found - stats.corrected

        if corrected_found_diff > 0
          message = Rainbow(
            "#{stats.corrected} error(s) corrected and #{corrected_found_diff} error(s) remaining in ERB files"
          ).red

          warn(message)
        else
          puts Rainbow("#{stats.corrected} error(s) corrected in ERB files").green
        end
      end
    end
  end
end
