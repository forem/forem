# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that `context` docstring starts with an allowed prefix.
      #
      # The default list of prefixes is minimal. Users are encouraged to tailor
      # the configuration to meet project needs. Other acceptable prefixes may
      # include `if`, `unless`, `for`, `before`, `after`, or `during`.
      # They may consist of multiple words if desired.
      #
      # @see http://www.betterspecs.org/#contexts
      #
      # @example `Prefixes` configuration
      #   # .rubocop.yml
      #   # RSpec/ContextWording:
      #   #   Prefixes:
      #   #     - when
      #   #     - with
      #   #     - without
      #   #     - if
      #   #     - unless
      #   #     - for
      #
      # @example
      #   # bad
      #   context 'the display name not present' do
      #     # ...
      #   end
      #
      #   # good
      #   context 'when the display name is not present' do
      #     # ...
      #   end
      #
      # This cop can be customized allowed context description pattern
      # with `AllowedPatterns`. By default, there are no checking by pattern.
      #
      # @example `AllowedPatterns` configuration
      #
      #   # .rubocop.yml
      #   # RSpec/ContextWording:
      #   #   AllowedPatterns:
      #   #     - とき$
      #
      # @example
      #   # bad
      #   context '条件を満たす' do
      #     # ...
      #   end
      #
      #   # good
      #   context '条件を満たすとき' do
      #     # ...
      #   end
      #
      class ContextWording < Base
        include AllowedPattern

        MSG = 'Context description should match %<patterns>s.'

        # @!method context_wording(node)
        def_node_matcher :context_wording, <<~PATTERN
          (block (send #rspec? { :context :shared_context } $({str dstr xstr} ...) ...) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          context_wording(node) do |context|
            if bad_pattern?(context)
              message = format(MSG, patterns: expect_patterns)
              add_offense(context, message: message)
            end
          end
        end

        private

        def allowed_patterns
          super + prefix_regexes
        end

        def prefix_regexes
          @prefix_regexes ||= prefixes.map { |pre| /^#{Regexp.escape(pre)}\b/ }
        end

        def bad_pattern?(node)
          return false if allowed_patterns.empty?

          !matches_allowed_pattern?(description(node))
        end

        def description(context)
          if context.xstr_type?
            context.value.value
          else
            context.value
          end
        end

        def expect_patterns
          inspected = allowed_patterns.map do |pattern|
            pattern.inspect.gsub(/\A"|"\z/, '/')
          end
          return inspected.first if inspected.size == 1

          inspected << "or #{inspected.pop}"
          inspected.join(', ')
        end

        def prefixes
          Array(cop_config.fetch('Prefixes', []))
        end
      end
    end
  end
end
