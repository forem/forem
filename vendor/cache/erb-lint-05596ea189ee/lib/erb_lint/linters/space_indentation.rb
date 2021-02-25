# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects indentation with tabs and autocorrect them to spaces
    class SpaceIndentation < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :tab_width, converts: :to_i, accepts: Integer, default: 2
      end
      self.config_schema = ConfigSchema

      START_SPACES = /\A([[:blank:]]*)/

      def run(processed_source)
        lines = processed_source.file_content.split("\n", -1)
        document_pos = 0
        lines.each do |line|
          spaces = line.match(START_SPACES)&.captures&.first

          if spaces.include?("\t")
            add_offense(
              processed_source.to_source_range(document_pos...(document_pos + spaces.length)),
              "Indent with spaces instead of tabs.",
              spaces.gsub("\t", ' ' * @config.tab_width)
            )
          end

          document_pos += line.length + 1
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
