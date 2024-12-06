# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for instance variables in partials.
    class PartialInstanceVariable < Linter
      include LinterRegistry

      def run(processed_source)
        instance_variable_regex = /\s@\w+/
        return unless processed_source.filename.match?(%r{(\A|.*/)_[^/\s]*\.html\.erb\z}) &&
          processed_source.file_content.match?(instance_variable_regex)

        add_offense(
          processed_source.to_source_range(
            processed_source.file_content =~ instance_variable_regex..processed_source.file_content.size
          ),
          "Instance variable detected in partial."
        )
      end
    end
  end
end
