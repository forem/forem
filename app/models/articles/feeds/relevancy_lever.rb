module Articles
  module Feeds
    # This simple data structure describes a configuration of SQL "clause" fragments used in
    # building a relevancy score for building the list of Articles queried for the feed.
    #
    # @see config/feed/README.md
    class RelevancyLever
      class ConfigurationError < StandardError
      end

      class InvalidFallbackError < ConfigurationError
        def initialize(fallback:, key:)
          super("Expected fallback to be a Numeric value for lever #{key.inspect}, got #{fallback.inspect}")
        end
      end

      class InvalidCasesError < ConfigurationError
        def initialize(cases:, key:)
          super("Expected cases to be an array of number pairs for lever #{key.inspect}, got #{cases.inspect}")
        end
      end

      class InvalidQueryParametersError < ConfigurationError
        def initialize(given_parameters:, expected_parameters:, key:)
          # rubocop:disable Layout/LineLength
          super("Expected query parameters #{expected_parameters.inspect}, got #{given_parameters.inspect} for lever #{key.inspect}")
          # rubocop:enable Layout/LineLength
        end
      end

      Configured = Struct.new(
        :key,
        :user_required,
        :select_fragment,
        :joins_fragments,
        :group_by_fragment,
        :cases,
        :fallback,
        :query_parameters,
        keyword_init: true,
      ) do
        alias_method :user_required?, :user_required
      end

      # @param key [Symbol] the programmatic means of naming this
      #        lever. (e.g. "publication_date_decay_lever")
      # @param label [String] the the "help text" for describing this lever.  (e.g. "How the
      #        publication date impacts relevancy score?")
      # @param range [String] the expected range of the query results.
      # @param user_required [Boolean] if true, this lever is only available when we are building
      #        the feed query for a given user.
      # @param select_fragment [String] a SQL `SELECT` fragment used to create the *lever range*
      # @param joins_fragments [Array<String>] an array of SQL `JOIN` fragments used to ensure the
      #         given :select_fragment can properly query the database.
      # @param group_by_fragment [String] a SQL `GROUP BY` fragment used to ensure the given
      #        :select_fragment can properly query the database.
      # @param query_parameter_names [Array<Symbol>] The names of variables needed for the SQL
      #        fragments.
      #
      # rubocop:disable Layout/LineLength
      def initialize(key:, label:, range:, user_required:, select_fragment:, joins_fragments: [], group_by_fragment: nil, query_parameter_names: [])
        @key = key.to_sym
        @label = label
        @range = range
        @user_required = user_required
        @select_fragment = select_fragment
        @joins_fragments = Array.wrap(joins_fragments)
        @group_by_fragment = group_by_fragment
        @query_parameter_names = Array.wrap(query_parameter_names).map(&:to_sym)
      end
      # rubocop:enable Layout/LineLength

      attr_reader :key, :label, :user_required, :select_fragment, :joins_fragments, :group_by_fragment,
                  :query_parameter_names

      alias user_required? user_required

      # Responsible for configuring the lever with the given input.
      #
      # @param cases [Array<Array<Integer, Float>>]
      # @param fallback [Float]
      # @param query_parameters [Hash<Symbol,Integer>] A Hash of the named query parameter and it's
      #        corresponding value.
      #
      # @return [Articles::Feeds::RelevancyLever::Configured]
      # @raise [Articles::Feeds::RelevancyLever::InvalidFallbackError] when the given fallback is
      #        invalid.
      # @raise [Articles::Feeds::RelevancyLever::InvalidCasesError] when the given cases is invalid.
      # @raise [Articles::Feeds::RelevancyLever::InvalidQueryParametersError] when the given query
      #        parameters are mismatched.
      def configure_with(cases:, fallback:, **query_parameters)
        raise InvalidFallbackError.new(fallback: fallback, key: key) unless valid_fallback?(fallback)
        raise InvalidCasesError.new(cases: cases, key: key) unless valid_cases?(cases)

        query_parameters = extract_query_parameters(query_parameters)

        Configured.new(
          key: key,
          user_required: user_required,
          select_fragment: select_fragment,
          joins_fragments: joins_fragments,
          group_by_fragment: group_by_fragment,
          cases: cases,
          fallback: fallback,
          query_parameters: query_parameters,
        )
      end

      private

      def extract_query_parameters(query_parameters)
        returning_value = {}
        query_parameter_names.each do |name|
          # Cast to string because the given query_parameters is almost certainly from JSON and has
          # a string key.
          returning_value[name] = query_parameters.fetch(name).to_i
        end
        returning_value
      rescue KeyError
        raise InvalidQueryParametersError.new(
          given_parameters: query_parameters.keys.map(&:to_sym),
          expected_parameters: query_parameter_names,
          key: key,
        )
      end

      def valid_fallback?(fallback)
        fallback.is_a?(Numeric)
      end

      def valid_cases?(cases)
        return false unless cases.is_a?(Array)

        cases.all? { |range, factor| range.is_a?(Numeric) && factor.is_a?(Numeric) }
      end
    end
  end
end
