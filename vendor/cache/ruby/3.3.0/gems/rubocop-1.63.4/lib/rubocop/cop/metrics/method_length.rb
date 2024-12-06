# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks if the length of a method exceeds some maximum value.
      # Comment lines can optionally be allowed.
      # The maximum allowed length is configurable.
      #
      # You can set constructs you want to fold with `CountAsOne`.
      # Available are: 'array', 'hash', 'heredoc', and 'method_call'. Each construct
      # will be counted as one line regardless of its actual size.
      #
      # NOTE: The `ExcludedMethods` and `IgnoredMethods` configuration is
      # deprecated and only kept for backwards compatibility.
      # Please use `AllowedMethods` and `AllowedPatterns` instead.
      # By default, there are no methods to allowed.
      #
      # @example CountAsOne: ['array', 'heredoc', 'method_call']
      #
      #   def m
      #     array = [       # +1
      #       1,
      #       2
      #     ]
      #
      #     hash = {        # +3
      #       key: 'value'
      #     }
      #
      #     <<~HEREDOC      # +1
      #       Heredoc
      #       content.
      #     HEREDOC
      #
      #     foo(            # +1
      #       1,
      #       2
      #     )
      #   end               # 6 points
      #
      class MethodLength < Base
        include CodeLength
        include AllowedMethods
        include AllowedPattern

        LABEL = 'Method'

        def on_def(node)
          return if allowed_method?(node.method_name) || matches_allowed_pattern?(node.method_name)

          check_code_length(node)
        end
        alias on_defs on_def

        def on_block(node)
          return unless node.method?(:define_method)

          check_code_length(node)
        end
        alias on_numblock on_block

        private

        def cop_label
          LABEL
        end
      end
    end
  end
end
