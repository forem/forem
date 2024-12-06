# frozen_string_literal: true

require "erb_lint/utils/inline_configs"

module ERBLint
  module Linters
    # Checks for unused disable comments.
    class NoUnusedDisable < Linter
      include LinterRegistry

      def run(processed_source, offenses)
        disabled_rules_and_line_number = {}

        processed_source.source_buffer.source_lines.each_with_index do |line, index|
          rule_disables = Utils::InlineConfigs.disabled_rules(line)
          next unless rule_disables

          rule_disables.split(",").each do |rule|
            disabled_rules_and_line_number[rule.strip] =
              (disabled_rules_and_line_number[rule.strip] ||= []).push(index + 1)
          end
        end

        offenses.each do |offense|
          rule_name = offense.linter.class.simple_name
          line_numbers = disabled_rules_and_line_number[rule_name]
          next unless line_numbers

          line_numbers.reject do |line_number|
            if (offense.source_range.line_span.first..offense.source_range.line_span.last).include?(line_number)
              disabled_rules_and_line_number[rule_name].delete(line_number)
            end
          end
        end

        disabled_rules_and_line_number.each do |rule, line_numbers|
          line_numbers.each do |line_number|
            add_offense(processed_source.source_buffer.line_range(line_number),
              "Unused erblint:disable comment for #{rule}")
          end
        end
      end
    end
  end
end
