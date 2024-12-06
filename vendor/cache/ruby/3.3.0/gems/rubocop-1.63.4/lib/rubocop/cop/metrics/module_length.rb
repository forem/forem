# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks if the length of a module exceeds some maximum value.
      # Comment lines can optionally be ignored.
      # The maximum allowed length is configurable.
      #
      # You can set constructs you want to fold with `CountAsOne`.
      # Available are: 'array', 'hash', 'heredoc', and 'method_call'. Each construct
      # will be counted as one line regardless of its actual size.
      #
      # @example CountAsOne: ['array', 'heredoc', 'method_call']
      #
      #   module M
      #     ARRAY = [         # +1
      #       1,
      #       2
      #     ]
      #
      #     HASH = {          # +3
      #       key: 'value'
      #     }
      #
      #     MSG = <<~HEREDOC  # +1
      #       Heredoc
      #       content.
      #     HEREDOC
      #
      #     foo(              # +1
      #       1,
      #       2
      #     )
      #   end                 # 6 points
      #
      class ModuleLength < Base
        include CodeLength

        def on_module(node)
          check_code_length(node)
        end

        def on_casgn(node)
          module_definition?(node) { check_code_length(node) }
        end

        private

        # @!method module_definition?(node)
        def_node_matcher :module_definition?, <<~PATTERN
          (casgn nil? _ ({block numblock} (send (const {nil? cbase} :Module) :new) ...))
        PATTERN

        def message(length, max_length)
          format('Module has too many lines. [%<length>d/%<max>d]', length: length, max: max_length)
        end
      end
    end
  end
end
