# frozen_string_literal: true

module Capybara
  module Queries
    class MatchQuery < Capybara::Queries::SelectorQuery
      def visible
        options.key?(:visible) ? super : :all
      end

    private

      def assert_valid_keys
        invalid_options = @options.keys & COUNT_KEYS
        unless invalid_options.empty?
          raise ArgumentError, "Match queries don't support quantity options. Invalid keys - #{invalid_options.join(', ')}"
        end

        super
      end

      def valid_keys
        super - COUNT_KEYS
      end
    end
  end
end
