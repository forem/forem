# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for final newlines at the end of a file.
    class FinalNewline < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :present, accepts: [true, false], default: true, reader: :present?
      end
      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        super
        @new_lines_should_be_present = @config.present?
      end

      def run(processed_source)
        file_content = processed_source.file_content

        return if file_content.empty?

        match = file_content.match(/(\n+)\z/)
        final_newline = match&.captures&.first || ""

        if @new_lines_should_be_present && final_newline.size != 1
          if final_newline.empty?
            add_offense(
              processed_source.to_source_range(file_content.size...file_content.size),
              'Missing a trailing newline at the end of the file.',
              :insert
            )
          else
            add_offense(
              processed_source.to_source_range(
                (file_content.size - final_newline.size + 1)...file_content.size
              ),
              'Remove multiple trailing newline at the end of the file.',
              :remove
            )
          end
        elsif !@new_lines_should_be_present && !final_newline.empty?
          add_offense(
            processed_source.to_source_range(match.begin(0)...match.end(0)),
            "Remove #{final_newline.size} trailing newline at the end of the file.",
            :remove
          )
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          if offense.context == :insert
            corrector.insert_after(offense.source_range, "\n")
          else
            corrector.remove_trailing(offense.source_range, offense.source_range.size)
          end
        end
      end
    end
  end
end
