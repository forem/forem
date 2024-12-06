# frozen_string_literal: true

module Capybara
  module SessionMatchers
    ##
    # Asserts that the page has the given path.
    # By default, if passed a full url this will compare against the full url,
    # if passed a path only the path+query portion will be compared, if passed a regexp
    # the comparison will depend on the :url option (path+query by default)
    #
    # @!macro current_path_query_params
    #   @overload $0(string, **options)
    #     @param string [String]           The string that the current 'path' should equal
    #   @overload $0(regexp, **options)
    #     @param regexp [Regexp]           The regexp that the current 'path' should match to
    #   @option options [Boolean] :url (true if `string` is a full url, otherwise false) Whether the comparison should be done against the full current url or just the path
    #   @option options [Boolean] :ignore_query (false)  Whether the query portion of the current url/path should be ignored
    #   @option options [Numeric] :wait (Capybara.default_max_wait_time) Maximum time that Capybara will wait for the current url/path to eq/match given string/regexp argument
    # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
    # @return [true]
    #
    def assert_current_path(path, **options, &optional_filter_block)
      _verify_current_path(path, optional_filter_block, **options) do |query|
        raise Capybara::ExpectationNotMet, query.failure_message unless query.resolves_for?(self)
      end
    end

    ##
    # Asserts that the page doesn't have the given path.
    # By default, if passed a full url this will compare against the full url,
    # if passed a path only the path+query portion will be compared, if passed a regexp
    # the comparison will depend on the :url option
    #
    # @macro current_path_query_params
    # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
    # @return [true]
    #
    def assert_no_current_path(path, **options, &optional_filter_block)
      _verify_current_path(path, optional_filter_block, **options) do |query|
        raise Capybara::ExpectationNotMet, query.negative_failure_message if query.resolves_for?(self)
      end
    end

    ##
    # Checks if the page has the given path.
    # By default, if passed a full url this will compare against the full url,
    # if passed a path only the path+query portion will be compared, if passed a regexp
    # the comparison will depend on the :url option
    #
    # @macro current_path_query_params
    # @return [Boolean]
    #
    def has_current_path?(path, **options, &optional_filter_block)
      make_predicate(options) { assert_current_path(path, **options, &optional_filter_block) }
    end

    ##
    # Checks if the page doesn't have the given path.
    # By default, if passed a full url this will compare against the full url,
    # if passed a path only the path+query portion will be compared, if passed a regexp
    # the comparison will depend on the :url option
    #
    # @macro current_path_query_params
    # @return [Boolean]
    #
    def has_no_current_path?(path, **options, &optional_filter_block)
      make_predicate(options) { assert_no_current_path(path, **options, &optional_filter_block) }
    end

  private

    def _verify_current_path(path, filter_block, **options)
      query = Capybara::Queries::CurrentPathQuery.new(path, **options, &filter_block)
      document.synchronize(query.wait) do
        yield(query)
      end
      true
    end

    def make_predicate(options)
      options[:wait] = 0 unless options.key?(:wait) || config.predicates_wait
      yield
    rescue Capybara::ExpectationNotMet
      false
    end
  end
end
