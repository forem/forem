# frozen_string_literal: true

require 'capybara/rspec/matchers/base'

module Capybara
  module RSpecMatchers
    module Matchers
      class HaveSibling < CountableWrappedElementMatcher
        def element_matches?(el)
          el.assert_sibling(*@args, **session_query_options, &@filter_block)
        end

        def element_does_not_match?(el)
          el.assert_no_sibling(*@args, **session_query_options, &@filter_block)
        end

        def description
          "have sibling #{query.description}"
        end

        def query
          @query ||= Capybara::Queries::SiblingQuery.new(*session_query_args, **session_query_options, &@filter_block)
        end
      end
    end
  end
end
