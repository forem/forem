# frozen_string_literal: true

require 'capybara/rspec/matchers/have_selector'

module Capybara
  module RSpecMatchers
    module Matchers
      class MatchSelector < HaveSelector
        def element_matches?(el)
          el.assert_matches_selector(*@args, **session_query_options, &@filter_block)
        end

        def element_does_not_match?(el)
          el.assert_not_matches_selector(*@args, **session_query_options, &@filter_block)
        end

        def description
          "match #{query.description}"
        end

        def query
          @query ||= Capybara::Queries::MatchQuery.new(*session_query_args, **session_query_options, &@filter_block)
        end
      end
    end
  end
end
