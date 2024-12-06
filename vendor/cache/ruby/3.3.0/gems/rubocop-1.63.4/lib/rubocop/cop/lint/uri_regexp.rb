# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Identifies places where `URI.regexp` is obsolete and should
      # not be used. Instead, use `URI::DEFAULT_PARSER.make_regexp`.
      #
      # @example
      #   # bad
      #   URI.regexp('http://example.com')
      #
      #   # good
      #   URI::DEFAULT_PARSER.make_regexp('http://example.com')
      #
      class UriRegexp < Base
        extend AutoCorrector

        MSG = '`%<current>s` is obsolete and should not be used. Instead, use `%<preferred>s`.'
        URI_CONSTANTS = ['URI', '::URI'].freeze
        RESTRICT_ON_SEND = %i[regexp].freeze

        def on_send(node)
          return unless node.receiver
          return unless URI_CONSTANTS.include?(node.receiver.source)

          argument = node.first_argument ? "(#{node.first_argument.source})" : ''
          preferred_method = "#{node.receiver.source}::DEFAULT_PARSER.make_regexp#{argument}"
          message = format(MSG, current: node.source, preferred: preferred_method)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.replace(node, preferred_method)
          end
        end
      end
    end
  end
end
