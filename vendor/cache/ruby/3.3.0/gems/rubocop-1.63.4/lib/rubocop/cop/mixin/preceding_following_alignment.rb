# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking whether an AST node/token is aligned
    # with something on a preceding or following line
    module PrecedingFollowingAlignment
      private

      def allow_for_alignment?
        cop_config['AllowForAlignment']
      end

      def aligned_with_something?(range)
        aligned_with_adjacent_line?(range, method(:aligned_token?))
      end

      def aligned_with_operator?(range)
        aligned_with_adjacent_line?(range, method(:aligned_operator?))
      end

      def aligned_with_preceding_assignment(token)
        preceding_line_range = token.line.downto(1)

        aligned_with_assignment(token, preceding_line_range)
      end

      def aligned_with_subsequent_assignment(token)
        subsequent_line_range = token.line.upto(processed_source.lines.length)

        aligned_with_assignment(token, subsequent_line_range)
      end

      def aligned_with_adjacent_line?(range, predicate)
        # minus 2 because node.loc.line is zero-based
        pre  = (range.line - 2).downto(0)
        post = range.line.upto(processed_source.lines.size - 1)

        aligned_with_any_line_range?([pre, post], range, &predicate)
      end

      def aligned_with_any_line_range?(line_ranges, range, &predicate)
        return true if aligned_with_any_line?(line_ranges, range, &predicate)

        # If no aligned token was found, search for an aligned token on the
        # nearest line with the same indentation as the checked line.
        base_indentation = processed_source.lines[range.line - 1] =~ /\S/

        aligned_with_any_line?(line_ranges, range, base_indentation, &predicate)
      end

      def aligned_with_any_line?(line_ranges, range, indent = nil, &predicate)
        line_ranges.any? { |line_nos| aligned_with_line?(line_nos, range, indent, &predicate) }
      end

      def aligned_with_line?(line_nos, range, indent = nil)
        line_nos.each do |lineno|
          next if aligned_comment_lines.include?(lineno + 1)

          line = processed_source.lines[lineno]
          index = line =~ /\S/
          next unless index
          next if indent && indent != index

          return yield(range, line)
        end
        false
      end

      def aligned_comment_lines
        @aligned_comment_lines ||=
          processed_source.comments.map(&:loc).select do |r|
            begins_its_line?(r.expression)
          end.map(&:line)
      end

      def aligned_token?(range, line)
        aligned_words?(range, line) || aligned_assignment?(range, line)
      end

      def aligned_operator?(range, line)
        aligned_identical?(range, line) || aligned_assignment?(range, line)
      end

      def aligned_words?(range, line)
        left_edge = range.column
        return true if /\s\S/.match?(line[left_edge - 1, 2])

        token = range.source
        token == line[left_edge, token.length]
      end

      def aligned_assignment?(range, line)
        (range.source[-1] == '=' && line[range.last_column - 1] == '=') ||
          aligned_with_append_operator?(range, line)
      end

      def aligned_with_append_operator?(range, line)
        last_column = range.last_column

        (range.source == '<<' && line[last_column - 1] == '=') ||
          (range.source[-1] == '=' && line[(last_column - 2)..(last_column - 1)] == '<<')
      end

      def aligned_identical?(range, line)
        range.source == line[range.column, range.size]
      end

      def aligned_with_assignment(token, line_range)
        token_line_indent    = processed_source.line_indentation(token.line)
        assignment_lines     = relevant_assignment_lines(line_range)
        relevant_line_number = assignment_lines[1]

        return :none unless relevant_line_number

        relevant_indent = processed_source.line_indentation(relevant_line_number)

        return :none if relevant_indent < token_line_indent

        assignment_line = processed_source.lines[relevant_line_number - 1]

        return :none unless assignment_line

        aligned_assignment?(token.pos, assignment_line) ? :yes : :no
      end

      def assignment_lines
        @assignment_lines ||= assignment_tokens.map(&:line)
      end

      def assignment_tokens
        @assignment_tokens ||= begin
          tokens = processed_source.tokens.select(&:equal_sign?)

          # we don't want to operate on equals signs which are part of an
          #   optarg in a method definition
          # e.g.: def method(optarg = default_val); end
          tokens = remove_optarg_equals(tokens, processed_source)

          # Only attempt to align the first = on each line
          Set.new(tokens.uniq(&:line))
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
      def relevant_assignment_lines(line_range)
        result                        = []
        original_line_indent          = processed_source.line_indentation(line_range.first)
        relevant_line_indent_at_level = true

        line_range.each do |line_number|
          current_line_indent = processed_source.line_indentation(line_number)
          blank_line          = processed_source.lines[line_number - 1].blank?

          if (current_line_indent < original_line_indent && !blank_line) ||
             (relevant_line_indent_at_level && blank_line)
            break
          end

          result << line_number if assignment_lines.include?(line_number) &&
                                   current_line_indent == original_line_indent

          unless blank_line
            relevant_line_indent_at_level = current_line_indent == original_line_indent
          end
        end

        result
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength

      def remove_optarg_equals(asgn_tokens, processed_source)
        optargs    = processed_source.ast.each_node(:optarg)
        optarg_eql = optargs.to_set { |o| o.loc.operator.begin_pos }
        asgn_tokens.reject { |t| optarg_eql.include?(t.begin_pos) }
      end
    end
  end
end
