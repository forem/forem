# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that all variables use the configured style,
      # snake_case or camelCase, for their names.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   fooBar = 1
      #
      #   # good
      #   foo_bar = 1
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   foo_bar = 1
      #
      #   # good
      #   fooBar = 1
      #
      # @example AllowedIdentifiers: ['fooBar']
      #   # good (with EnforcedStyle: snake_case)
      #   fooBar = 1
      #
      # @example AllowedPatterns: ['_v\d+\z']
      #   # good (with EnforcedStyle: camelCase)
      #   :release_v1
      #
      class VariableName < Base
        include AllowedIdentifiers
        include ConfigurableNaming
        include AllowedPattern

        MSG = 'Use %<style>s for variable names.'

        def valid_name?(node, name, given_style = style)
          super || matches_allowed_pattern?(name)
        end

        def on_lvasgn(node)
          name, = *node
          return unless name
          return if allowed_identifier?(name)

          check_name(node, name, node.loc.name)
        end
        alias on_ivasgn    on_lvasgn
        alias on_cvasgn    on_lvasgn
        alias on_arg       on_lvasgn
        alias on_optarg    on_lvasgn
        alias on_restarg   on_lvasgn
        alias on_kwoptarg  on_lvasgn
        alias on_kwarg     on_lvasgn
        alias on_kwrestarg on_lvasgn
        alias on_blockarg  on_lvasgn
        alias on_lvar      on_lvasgn

        private

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
