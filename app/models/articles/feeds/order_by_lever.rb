module Articles
  module Feeds
    # This simple data structure describes a configuration of SQL "clause" fragments used in
    # sorting the list of Articles queried for the feed.
    #
    # @see config/feed/README.md
    class OrderByLever
      # @param key [Symbol] the programmatic means of naming this
      #        lever. (e.g. "publication_date_decay_lever")
      # @param label [String] the "help text" for describing this lever.  (e.g. "How the
      #        publication date impacts relevancy score?")
      # @param order_by_fragment [String] a SQL `ORDER` fragment
      def initialize(key:, label:, order_by_fragment:)
        @key = key.to_sym
        @label = label
        @order_by_fragment = order_by_fragment
      end
      attr_reader :key, :label, :order_by_fragment

      def to_sql
        Arel.sql(order_by_fragment)
      end
    end
  end
end
