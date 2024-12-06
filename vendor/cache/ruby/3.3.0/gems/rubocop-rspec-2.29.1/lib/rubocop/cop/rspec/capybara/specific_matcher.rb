# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks for there is a more specific matcher offered by Capybara.
        #   #
        #   # @example
        #   #
        #   #   # bad
        #   #   expect(page).to have_selector('button')
        #   #   expect(page).to have_no_selector('button.cls')
        #   #   expect(page).to have_css('button')
        #   #   expect(page).to have_no_css('a.cls', href: 'http://example.com')
        #   #   expect(page).to have_css('table.cls')
        #   #   expect(page).to have_css('select')
        #   #   expect(page).to have_css('input', exact_text: 'foo')
        #   #
        #   #   # good
        #   #   expect(page).to have_button
        #   #   expect(page).to have_no_button(class: 'cls')
        #   #   expect(page).to have_button
        #   #   expect(page).to have_no_link('foo', class: 'cls', href: 'http://example.com')
        #   #   expect(page).to have_table(class: 'cls')
        #   #   expect(page).to have_select
        #   #   expect(page).to have_field('foo')
        #   #
        #   class SpecificMatcher < ::RuboCop::Cop::Base; end
        SpecificMatcher = ::RuboCop::Cop::Capybara::SpecificMatcher
      end
    end
  end
end
