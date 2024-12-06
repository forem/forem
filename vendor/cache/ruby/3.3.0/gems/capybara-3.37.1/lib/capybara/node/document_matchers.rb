# frozen_string_literal: true

module Capybara
  module Node
    module DocumentMatchers
      ##
      # Asserts that the page has the given title.
      #
      # @!macro title_query_params
      #   @overload $0(string, **options)
      #     @param string [String]           The string that title should include
      #   @overload $0(regexp, **options)
      #     @param regexp [Regexp]           The regexp that title should match to
      #   @option options [Numeric] :wait (Capybara.default_max_wait_time) Maximum time that Capybara will wait for title to eq/match given string/regexp argument
      #   @option options [Boolean] :exact (false) When passed a string should the match be exact or just substring
      # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
      # @return [true]
      #
      def assert_title(title, **options)
        _verify_title(title, options) do |query|
          raise Capybara::ExpectationNotMet, query.failure_message unless query.resolves_for?(self)
        end
      end

      ##
      # Asserts that the page doesn't have the given title.
      #
      # @macro title_query_params
      # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
      # @return [true]
      #
      def assert_no_title(title, **options)
        _verify_title(title, options) do |query|
          raise Capybara::ExpectationNotMet, query.negative_failure_message if query.resolves_for?(self)
        end
      end

      ##
      # Checks if the page has the given title.
      #
      # @macro title_query_params
      # @return [Boolean]
      #
      def has_title?(title, **options)
        make_predicate(options) { assert_title(title, **options) }
      end

      ##
      # Checks if the page doesn't have the given title.
      #
      # @macro title_query_params
      # @return [Boolean]
      #
      def has_no_title?(title, **options)
        make_predicate(options) { assert_no_title(title, **options) }
      end

    private

      def _verify_title(title, options)
        query = Capybara::Queries::TitleQuery.new(title, **options)
        synchronize(query.wait) { yield(query) }
        true
      end
    end
  end
end
