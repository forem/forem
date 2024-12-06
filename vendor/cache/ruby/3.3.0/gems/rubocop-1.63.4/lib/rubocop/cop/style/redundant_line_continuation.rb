# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Check for redundant line continuation.
      #
      # This cop marks a line continuation as redundant if removing the backslash
      # does not result in a syntax error.
      # However, a backslash at the end of a comment or
      # for string concatenation is not redundant and is not considered an offense.
      #
      # @example
      #   # bad
      #   foo. \
      #     bar
      #   foo \
      #     &.bar \
      #       .baz
      #
      #   # good
      #   foo.
      #     bar
      #   foo
      #     &.bar
      #       .baz
      #
      #   # bad
      #   [foo, \
      #     bar]
      #   {foo: \
      #     bar}
      #
      #   # good
      #   [foo,
      #     bar]
      #   {foo:
      #     bar}
      #
      #   # bad
      #   foo(bar, \
      #     baz)
      #
      #   # good
      #   foo(bar,
      #     baz)
      #
      #   # also good - backslash in string concatenation is not redundant
      #   foo('bar' \
      #     'baz')
      #
      #   # also good - backslash at the end of a comment is not redundant
      #   foo(bar, # \
      #     baz)
      #
      #   # also good - backslash at the line following the newline begins with a + or -,
      #   # it is not redundant
      #   1 \
      #     + 2 \
      #       - 3
      #
      #   # also good - backslash with newline between the method name and its arguments,
      #   # it is not redundant.
      #   some_method \
      #     (argument)
      #
      class RedundantLineContinuation < Base
        include MatchRange
        extend AutoCorrector

        MSG = 'Redundant line continuation.'
        ALLOWED_STRING_TOKENS = %i[tSTRING tSTRING_CONTENT].freeze
        ARGUMENT_TYPES = %i[
          kFALSE kNIL kSELF kTRUE tCONSTANT tCVAR tFLOAT tGVAR tIDENTIFIER tINTEGER tIVAR
          tLBRACK tLCURLY tLPAREN_ARG tSTRING tSTRING_BEG tSYMBOL tXSTRING_BEG
        ].freeze

        def on_new_investigation
          return unless processed_source.ast

          each_match_range(processed_source.ast.source_range, /(\\\n)/) do |range|
            next if require_line_continuation?(range)
            next unless redundant_line_continuation?(range)

            add_offense(range) do |corrector|
              corrector.remove_leading(range, 1)
            end
          end
        end

        private

        def require_line_continuation?(range)
          !ends_with_backslash_without_comment?(range.source_line) ||
            string_concatenation?(range.source_line) ||
            start_with_arithmetic_operator?(processed_source[range.line]) ||
            inside_string_literal_or_method_with_argument?(range) ||
            leading_dot_method_chain_with_blank_line?(range)
        end

        def ends_with_backslash_without_comment?(source_line)
          source_line.gsub(/#.+/, '').end_with?('\\')
        end

        def string_concatenation?(source_line)
          /["']\s*\\\z/.match?(source_line)
        end

        def inside_string_literal_or_method_with_argument?(range)
          processed_source.tokens.each_cons(2).any? do |token, next_token|
            next if token.line == next_token.line

            inside_string_literal?(range, token) || method_with_argument?(token, next_token)
          end
        end

        def leading_dot_method_chain_with_blank_line?(range)
          return false unless range.source_line.strip.start_with?('.', '&.')

          processed_source[range.line].strip.empty?
        end

        def redundant_line_continuation?(range)
          return true unless (node = find_node_for_line(range.line))
          return false if argument_newline?(node)

          source = node.parent ? node.parent.source : node.source
          parse(source.gsub("\\\n", "\n")).valid_syntax?
        end

        def inside_string_literal?(range, token)
          ALLOWED_STRING_TOKENS.include?(token.type) && token.pos.overlaps?(range)
        end

        # A method call without parentheses such as the following cannot remove `\`:
        #
        #   do_something \
        #     argument
        def method_with_argument?(current_token, next_token)
          return false if current_token.type != :tIDENTIFIER && current_token.type != :kRETURN

          ARGUMENT_TYPES.include?(next_token.type)
        end

        # rubocop:disable Metrics/AbcSize
        def argument_newline?(node)
          node = node.to_a.last if node.assignment?
          return false if node.parenthesized_call?

          node = node.children.first if node.root? && node.begin_type?

          if argument_is_method?(node)
            argument_newline?(node.first_argument)
          else
            return false unless method_call_with_arguments?(node)

            node.loc.selector.line != node.first_argument.loc.line
          end
        end
        # rubocop:enable Metrics/AbcSize

        def find_node_for_line(line)
          processed_source.ast.each_node do |node|
            return node if same_line?(node, line)
          end
        end

        def same_line?(node, line)
          return false unless (source_range = node.source_range)

          if node.is_a?(AST::StrNode)
            if node.heredoc?
              (node.loc.heredoc_body.line..node.loc.heredoc_body.last_line).cover?(line)
            else
              (source_range.line..source_range.last_line).cover?(line)
            end
          else
            source_range.line == line
          end
        end

        def argument_is_method?(node)
          return false unless node.send_type?
          return false unless (first_argument = node.first_argument)

          method_call_with_arguments?(first_argument)
        end

        def method_call_with_arguments?(node)
          node.call_type? && !node.arguments.empty?
        end

        def start_with_arithmetic_operator?(source_line)
          %r{\A\s*[+\-*/%]}.match?(source_line)
        end
      end
    end
  end
end
