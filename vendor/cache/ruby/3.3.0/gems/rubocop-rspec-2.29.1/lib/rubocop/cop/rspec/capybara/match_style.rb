# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks for usage of deprecated style methods.
        #   #
        #   # @example when using `assert_style`
        #   #   # bad
        #   #   page.find(:css, '#first').assert_style(display: 'block')
        #   #
        #   #   # good
        #   #   page.find(:css, '#first').assert_matches_style(display: 'block')
        #   #
        #   # @example when using `has_style?`
        #   #   # bad
        #   #   expect(page.find(:css, 'first')
        #   #     .has_style?(display: 'block')).to be true
        #   #
        #   #   # good
        #   #   expect(page.find(:css, 'first')
        #   #     .matches_style?(display: 'block')).to be true
        #   #
        #   # @example when using `have_style`
        #   #   # bad
        #   #   expect(page).to have_style(display: 'block')
        #   #
        #   #   # good
        #   #   expect(page).to match_style(display: 'block')
        #   #
        #   class MatchStyle < ::RuboCop::Cop::Base; end
        MatchStyle = ::RuboCop::Cop::Capybara::MatchStyle
      end
    end
  end
end
