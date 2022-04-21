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

      Configured = Struct.new(
        :key,
        :user_required,
        :select_fragment,
        :joins_fragments,
        :group_by_fragment,
        :cases,
        :fallback,
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
      # rubocop:disable Layout/LineLength
      def initialize(key:, label:, range:, user_required:, select_fragment:, joins_fragments: [], group_by_fragment: nil)
        @key = key.to_sym
        @label = label
        @range = range
        @user_required = user_required
        @select_fragment = select_fragment
        @joins_fragments = Array.wrap(joins_fragments)
        @group_by_fragment = group_by_fragment
      end
      # rubocop:enable Layout/LineLength

      attr_reader :key, :label, :user_required, :select_fragment, :joins_fragments, :group_by_fragment

      alias user_required? user_required

      # Responsible for configuring the lever with the given input.
      #
      # @param cases [Array<Array<Integer, Float>>]
      # @param fallback [Float]
      #
      # @return [Articles::Feeds::RelevancyLever::Configured]
      # @raise [Articles::Feeds::RelevancyLever::InvalidFallbackError] when the given fallback is
      #        invalid.
      # @raise [Articles::Feeds::RelevancyLever::InvaidCasesError] when the given cases is invalid.
      def configure_with(cases:, fallback:)
        raise InvalidFallbackError.new(fallback: fallback, key: key) unless valid_fallback?(fallback)
        raise InvalidCasesError.new(cases: cases, key: key) unless valid_cases?(cases)

        Configured.new(
          key: key,
          user_required: user_required,
          select_fragment: select_fragment,
          joins_fragments: joins_fragments,
          group_by_fragment: group_by_fragment,
          cases: cases,
          fallback: fallback,
        )
      end

      private

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
