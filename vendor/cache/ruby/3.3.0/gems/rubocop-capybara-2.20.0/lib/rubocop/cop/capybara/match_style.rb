# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for usage of deprecated style methods.
      #
      # @example when using `assert_style`
      #   # bad
      #   page.find(:css, '#first').assert_style(display: 'block')
      #
      #   # good
      #   page.find(:css, '#first').assert_matches_style(display: 'block')
      #
      # @example when using `has_style?`
      #   # bad
      #   expect(page.find(:css, 'first')
      #     .has_style?(display: 'block')).to be true
      #
      #   # good
      #   expect(page.find(:css, 'first')
      #     .matches_style?(display: 'block')).to be true
      #
      # @example when using `have_style`
      #   # bad
      #   expect(page).to have_style(display: 'block')
      #
      #   # good
      #   expect(page).to match_style(display: 'block')
      #
      class MatchStyle < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `%<good>s` instead of `%<bad>s`.'
        RESTRICT_ON_SEND = %i[assert_style has_style? have_style].freeze
        PREFERRED_METHOD = {
          'assert_style' => 'assert_matches_style',
          'has_style?' => 'matches_style?',
          'have_style' => 'match_style'
        }.freeze

        def on_send(node)
          method_node = node.loc.selector
          add_offense(method_node) do |corrector|
            corrector.replace(method_node,
                              PREFERRED_METHOD[method_node.source])
          end
        end

        private

        def message(node)
          format(MSG, good: PREFERRED_METHOD[node.source], bad: node.source)
        end
      end
    end
  end
end
