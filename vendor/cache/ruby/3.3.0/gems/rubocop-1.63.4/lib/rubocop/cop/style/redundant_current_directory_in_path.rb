# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses a redundant current directory in path.
      #
      # @example
      #
      #   # bad
      #   require_relative './path/to/feature'
      #
      #   # good
      #   require_relative 'path/to/feature'
      #
      class RedundantCurrentDirectoryInPath < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the redundant current directory path.'
        RESTRICT_ON_SEND = %i[require_relative].freeze
        CURRENT_DIRECTORY_PATH = './'

        def on_send(node)
          return unless (first_argument = node.first_argument)
          return unless first_argument.str_content&.start_with?(CURRENT_DIRECTORY_PATH)
          return unless (index = first_argument.source.index(CURRENT_DIRECTORY_PATH))

          begin_pos = first_argument.source_range.begin.begin_pos + index
          range = range_between(begin_pos, begin_pos + 2)

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end
      end
    end
  end
end
