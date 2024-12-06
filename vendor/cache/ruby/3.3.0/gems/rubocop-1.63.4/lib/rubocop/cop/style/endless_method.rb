# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for endless methods.
      #
      # It can enforce either the use of endless methods definitions
      # for single-lined method bodies, or disallow endless methods.
      #
      # Other method definition types are not considered by this cop.
      #
      # The supported styles are:
      #
      # * allow_single_line (default) - only single line endless method definitions are allowed.
      # * allow_always - all endless method definitions are allowed.
      # * disallow - all endless method definitions are disallowed.
      #
      # NOTE: Incorrect endless method definitions will always be
      # corrected to a multi-line definition.
      #
      # @example EnforcedStyle: allow_single_line (default)
      #   # good
      #   def my_method() = x
      #
      #   # bad, multi-line endless method
      #   def my_method() = x.foo
      #                      .bar
      #                      .baz
      #
      # @example EnforcedStyle: allow_always
      #   # good
      #   def my_method() = x
      #
      #   # good
      #   def my_method() = x.foo
      #                      .bar
      #                      .baz
      #
      # @example EnforcedStyle: disallow
      #   # bad
      #   def my_method() = x
      #
      #   # bad
      #   def my_method() = x.foo
      #                      .bar
      #                      .baz
      #
      class EndlessMethod < Base
        include ConfigurableEnforcedStyle
        extend TargetRubyVersion
        extend AutoCorrector

        minimum_target_ruby_version 3.0

        CORRECTION_STYLES = %w[multiline single_line].freeze
        MSG = 'Avoid endless method definitions.'
        MSG_MULTI_LINE = 'Avoid endless method definitions with multiple lines.'

        def on_def(node)
          if style == :disallow
            handle_disallow_style(node)
          else
            handle_allow_style(node)
          end
        end

        private

        def handle_allow_style(node)
          return unless node.endless?
          return if node.single_line? || style == :allow_always

          add_offense(node, message: MSG_MULTI_LINE) do |corrector|
            correct_to_multiline(corrector, node)
          end
        end

        def handle_disallow_style(node)
          return unless node.endless?

          add_offense(node) { |corrector| correct_to_multiline(corrector, node) }
        end

        def correct_to_multiline(corrector, node)
          replacement = <<~RUBY.strip
            def #{node.method_name}#{arguments(node)}
              #{node.body.source}
            end
          RUBY

          corrector.replace(node, replacement)
        end

        def arguments(node, missing = '')
          node.arguments.any? ? node.arguments.source : missing
        end
      end
    end
  end
end
