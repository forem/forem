module Search
  module QueryBuilders
    class ClassifiedListing < QueryBase
      TERM_KEYS = %i[
        category
        contact_via_connect
        location
        published
        slug
        tags
        title
        user_id
      ].freeze

      RANGE_KEYS = %i[
        bumped_at
        expires_at
      ].freeze

      QUERY_KEYS = %i[
        classified_listing_search
      ].freeze

      DEFAULT_PARAMS = {
        published: true,
        sort_by: "bumped_at",
        sort_direction: "desc",
        size: 0
      }.freeze

      def initialize(params)
        @params = params.deep_symbolize_keys

        # For now, we're not allowing searches for ClassifiedListings that are
        # not published. If we want to change this in the future we can do:
        # @params[:published] = DEFAULT_PARAMS[:published] unless @params.key?(:published)
        @params[:published] = DEFAULT_PARAMS[:published]

        build_body
      end

      private

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:filter] = filter_conditions
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end

      def filter_conditions
        filter_conditions = []

        # term_keys are always present because we are setting a filter of
        # published: true by default
        filter_conditions.concat term_keys

        filter_conditions.concat range_keys if range_keys_present?

        filter_conditions
      end

      def term_keys
        TERM_KEYS.map do |term_key|
          next unless @params.key? term_key

          { term: { term_key => @params[term_key] } }
        end.compact
      end

      def range_keys
        RANGE_KEYS.map do |range_key|
          next unless @params.key? range_key

          { range: { range_key => @params[range_key] } }
        end.compact
      end

      def range_keys_present?
        RANGE_KEYS.detect { |key| @params[key].present? }
      end
    end
  end
end
