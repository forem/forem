# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # @!parse
        #   # Checks for boolean visibility in Capybara finders.
        #   #
        #   # Capybara lets you find elements that match a certain visibility
        #   # using the `:visible` option. `:visible` accepts both boolean and
        #   # symbols as values, however using booleans can have unwanted
        #   # effects. `visible: false` does not find just invisible elements,
        #   # but both visible and invisible elements. For expressiveness and
        #   # clarity, use one of the # symbol values, `:all`, `:hidden` or
        #   # `:visible`.
        #   # Read more in
        #   # https://www.rubydoc.info/gems/capybara/Capybara%2FNode%2FFinders:all[the documentation].
        #   #
        #   # @example
        #   #   # bad
        #   #   expect(page).to have_selector('.foo', visible: false)
        #   #   expect(page).to have_css('.foo', visible: true)
        #   #   expect(page).to have_link('my link', visible: false)
        #   #
        #   #   # good
        #   #   expect(page).to have_selector('.foo', visible: :visible)
        #   #   expect(page).to have_css('.foo', visible: :all)
        #   #   expect(page).to have_link('my link', visible: :hidden)
        #   #
        #   class VisibilityMatcher < ::RuboCop::Cop::Base; end
        VisibilityMatcher = ::RuboCop::Cop::Capybara::VisibilityMatcher
      end
    end
  end
end
