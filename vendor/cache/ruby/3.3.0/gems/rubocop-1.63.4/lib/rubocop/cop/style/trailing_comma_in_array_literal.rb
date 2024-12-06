# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing comma in array literals.
      # The configuration options are:
      #
      # * `consistent_comma`: Requires a comma after the
      # last item of all non-empty, multiline array literals.
      # * `comma`: Requires a comma after last item in an array,
      # but only when each item is on its own line.
      # * `no_comma`: Does not require a comma after the
      # last item in an array
      #
      # @example EnforcedStyleForMultiline: consistent_comma
      #   # bad
      #   a = [1, 2,]
      #
      #   # good
      #   a = [1, 2]
      #
      #   # good
      #   a = [
      #     1, 2,
      #     3,
      #   ]
      #
      #   # good
      #   a = [
      #     1, 2, 3,
      #   ]
      #
      #   # good
      #   a = [
      #     1,
      #     2,
      #   ]
      #
      # @example EnforcedStyleForMultiline: comma
      #   # bad
      #   a = [1, 2,]
      #
      #   # good
      #   a = [1, 2]
      #
      #   # bad
      #   a = [
      #     1, 2,
      #     3,
      #   ]
      #
      #   # good
      #   a = [
      #     1, 2,
      #     3
      #   ]
      #
      #   # bad
      #   a = [
      #     1, 2, 3,
      #   ]
      #
      #   # good
      #   a = [
      #     1, 2, 3
      #   ]
      #
      #   # good
      #   a = [
      #     1,
      #     2,
      #   ]
      #
      # @example EnforcedStyleForMultiline: no_comma (default)
      #   # bad
      #   a = [1, 2,]
      #
      #   # good
      #   a = [
      #     1,
      #     2
      #   ]
      class TrailingCommaInArrayLiteral < Base
        include TrailingComma
        extend AutoCorrector

        def on_array(node)
          return unless node.square_brackets?

          check_literal(node, 'item of %<article>s array')
        end
      end
    end
  end
end
