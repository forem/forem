# frozen_string_literal: true

module Capybara
  # @api private
  module Queries
    class TitleQuery < BaseQuery
      def initialize(expected_title, **options)
        @expected_title = expected_title.is_a?(Regexp) ? expected_title : expected_title.to_s
        @options = options
        super(@options)
        @search_regexp = Helpers.to_regexp(@expected_title, all_whitespace: true, exact: options.fetch(:exact, false))
        assert_valid_keys
      end

      def resolves_for?(node)
        (@actual_title = node.title).match?(@search_regexp)
      end

      def failure_message
        failure_message_helper
      end

      def negative_failure_message
        failure_message_helper(' not')
      end

    private

      def failure_message_helper(negated = '')
        verb = @expected_title.is_a?(Regexp) ? 'match' : 'include'
        "expected #{@actual_title.inspect}#{negated} to #{verb} #{@expected_title.inspect}"
      end

      def valid_keys
        %i[wait exact]
      end
    end
  end
end
