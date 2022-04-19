module Articles
  module Feeds
    # This simple data structure describes a configuration of SQL "clause" fragments used in
    # building a relevancy score for building the list of Articles queried for the feed.
    #
    # @see config/feed/README.md
    class RelevancyLever
      # @param key [Symbol] the programmatic means of naming this
      #        lever. (e.g. "publication_date_decay_lever")
      # @param label [String] the the "help text" for describing this lever.  (e.g. "How the
      #        publication date impacts relevancy score?")
      # @param user_required [Boolean] if true, this lever is only available when we are building
      #        the feed query for a given user.
      # @param select_fragment [String] a SQL `SELECT` fragment used to create the *lever range*
      # @param joins_fragment [Array<String>] an array of SQL `JOIN` fragments used to ensure the
      #         given :select_fragment can properly query the database.
      # @param group_by_fragment [String] a SQL `GROUP BY` fragment used to ensure the given
      #        :select_fragment can properly query the database.
      def initialize(key:, label:, user_required:, select_fragment:, joins_fragment: [], group_by_fragment: nil)
        @key = key.to_sym
        @label = label
        @user_required = user_required
        @select_fragment = select_fragment
        @joins_fragment = Array.wrap(joins_fragment)
        @group_by_fragment = group_by_fragment
      end

      attr_reader :key, :label, :user_required, :select_fragment, :joins_fragment, :group_by_fragment

      alias user_required? user_required
    end
  end
end
