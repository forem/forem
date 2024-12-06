# frozen_string_literal: true

module RuboCop
  module Cop
    # This module encapsulates the logic for autocorrect behavior for a cop.
    module AutocorrectLogic
      def autocorrect?
        autocorrect_requested? && correctable? && autocorrect_enabled?
      end

      def autocorrect_with_disable_uncorrectable?
        autocorrect_requested? && disable_uncorrectable? && autocorrect_enabled?
      end

      def autocorrect_requested?
        @options.fetch(:autocorrect, false)
      end

      def correctable?
        self.class.support_autocorrect? || disable_uncorrectable?
      end

      def disable_uncorrectable?
        @options[:disable_uncorrectable] == true
      end

      def safe_autocorrect?
        cop_config.fetch('Safe', true) && cop_config.fetch('SafeAutoCorrect', true)
      end

      def autocorrect_enabled?
        # allow turning off autocorrect on a cop by cop basis
        return true unless cop_config

        # `false` is the same as `disabled` for backward compatibility.
        return false if ['disabled', false].include?(cop_config['AutoCorrect'])

        # When LSP is enabled, it is considered as editing source code,
        # and autocorrection with `AutoCorrect: contextual` will not be performed.
        return false if contextual_autocorrect? && LSP.enabled?

        # :safe_autocorrect is a derived option based on several command-line
        # arguments - see RuboCop::Options#add_autocorrection_options
        return safe_autocorrect? if @options.fetch(:safe_autocorrect, false)

        true
      end

      private

      def disable_offense(offense_range)
        range = surrounding_heredoc(offense_range) || surrounding_percent_array(offense_range)

        if range
          disable_offense_before_and_after(range_by_lines(range))
        else
          disable_offense_with_eol_or_surround_comment(offense_range)
        end
      end

      def disable_offense_with_eol_or_surround_comment(range)
        eol_comment = " # rubocop:todo #{cop_name}"
        needed_line_length = (range.source_line + eol_comment).length

        if needed_line_length <= max_line_length
          disable_offense_at_end_of_line(range_of_first_line(range), eol_comment)
        else
          disable_offense_before_and_after(range_by_lines(range))
        end
      end

      def surrounding_heredoc(offense_range)
        # The empty offense range is an edge case that can be reached from the Lint/Syntax cop.
        return nil if offense_range.empty?

        heredoc_nodes = processed_source.ast.each_descendant.select do |node|
          node.respond_to?(:heredoc?) && node.heredoc?
        end
        heredoc_nodes.map { |node| node.source_range.join(node.loc.heredoc_end) }
                     .find { |range| range.contains?(offense_range) }
      end

      def surrounding_percent_array(offense_range)
        return nil if offense_range.empty?

        percent_array = processed_source.ast.each_descendant.select do |node|
          node.array_type? && node.percent_literal?
        end

        percent_array.map(&:source_range).find do |range|
          offense_range.begin_pos > range.begin_pos && range.overlaps?(offense_range)
        end
      end

      def range_of_first_line(range)
        begin_of_first_line = range.begin_pos - range.column
        end_of_first_line = begin_of_first_line + range.source_line.length

        Parser::Source::Range.new(range.source_buffer, begin_of_first_line, end_of_first_line)
      end

      # Expand the given range to include all of any lines it covers. Does not
      # include newline at end of the last line.
      def range_by_lines(range)
        begin_of_first_line = range.begin_pos - range.column

        last_line = range.source_buffer.source_line(range.last_line)
        last_line_offset = last_line.length - range.last_column
        end_of_last_line = range.end_pos + last_line_offset

        Parser::Source::Range.new(range.source_buffer, begin_of_first_line, end_of_last_line)
      end

      def max_line_length
        config.for_cop('Layout/LineLength')['Max'] || 120
      end

      def disable_offense_at_end_of_line(range, eol_comment)
        Corrector.new(range).insert_after(range, eol_comment)
      end

      def disable_offense_before_and_after(range_by_lines)
        range_with_newline = range_by_lines.resize(range_by_lines.size + 1)
        leading_whitespace = range_by_lines.source_line[/^\s*/]

        Corrector.new(range_by_lines).wrap(
          range_with_newline,
          "#{leading_whitespace}# rubocop:todo #{cop_name}\n",
          "#{leading_whitespace}# rubocop:enable #{cop_name}\n"
        )
      end
    end
  end
end
