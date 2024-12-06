# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks for there is a more specific actions offered by Capybara.
        #   #
        #   # @example
        #   #
        #   #   # bad
        #   #   find('a').click
        #   #   find('button.cls').click
        #   #   find('a', exact_text: 'foo').click
        #   #   find('div button').click
        #   #
        #   #   # good
        #   #   click_link
        #   #   click_button(class: 'cls')
        #   #   click_link(exact_text: 'foo')
        #   #   find('div').click_button
        #   #
        #   class SpecificActions < ::RuboCop::Cop::Base; end
        SpecificActions = ::RuboCop::Cop::Capybara::SpecificActions
      end
    end
  end
end
