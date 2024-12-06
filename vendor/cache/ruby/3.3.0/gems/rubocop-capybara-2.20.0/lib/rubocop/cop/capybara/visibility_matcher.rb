# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for boolean visibility in Capybara finders.
      #
      # Capybara lets you find elements that match a certain visibility using
      # the `:visible` option. `:visible` accepts both boolean and symbols as
      # values, however using booleans can have unwanted effects. `visible:
      # false` does not find just invisible elements, but both visible and
      # invisible elements. For expressiveness and clarity, use one of the
      # symbol values, `:all`, `:hidden` or `:visible`.
      # Read more in
      # https://www.rubydoc.info/gems/capybara/Capybara%2FNode%2FFinders:all[the documentation].
      #
      # @example
      #   # bad
      #   expect(page).to have_selector('.foo', visible: false)
      #   expect(page).to have_css('.foo', visible: true)
      #   expect(page).to have_link('my link', visible: false)
      #
      #   # good
      #   expect(page).to have_selector('.foo', visible: :visible)
      #   expect(page).to have_css('.foo', visible: :all)
      #   expect(page).to have_link('my link', visible: :hidden)
      #
      class VisibilityMatcher < ::RuboCop::Cop::Base
        MSG_FALSE = 'Use `:all` or `:hidden` instead of `false`.'
        MSG_TRUE = 'Use `:visible` instead of `true`.'
        CAPYBARA_MATCHER_METHODS = %w[
          button
          checked_field
          css
          field
          link
          select
          selector
          table
          unchecked_field
          xpath
        ].flat_map do |element|
          ["have_#{element}".to_sym, "have_no_#{element}".to_sym]
        end

        RESTRICT_ON_SEND = CAPYBARA_MATCHER_METHODS

        # @!method visible_true?(node)
        def_node_matcher :visible_true?, <<~PATTERN
          (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) true) ...>))
        PATTERN

        # @!method visible_false?(node)
        def_node_matcher :visible_false?, <<~PATTERN
          (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) false) ...>))
        PATTERN

        def on_send(node)
          visible_false?(node) { |arg| add_offense(arg, message: MSG_FALSE) }
          visible_true?(node) { |arg| add_offense(arg, message: MSG_TRUE) }
        end

        private

        def capybara_matcher?(method_name)
          CAPYBARA_MATCHER_METHODS.include? method_name
        end
      end
    end
  end
end
