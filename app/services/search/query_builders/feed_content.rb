module Search
  module QueryBuilders
    class FeedContent < QueryBase
      QUERY_KEYS = %i[
        search_fields
      ].freeze

      TERM_KEYS = {
        tag_names: "tags.name",
        approved: "approved",
        user_id: "user.id",
        class_name: "class_name"
      }.freeze

      RANGE_KEYS = %i[
        published_at
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "hotness_score",
        sort_direction: "desc",
        size: 0
      }.freeze

      attr_accessor :params, :body

      def initialize(params)
        @params = params.deep_symbolize_keys
        build_body
      end

      private

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:filter] = filter_conditions if filter_keys_present?
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end

      def filter_conditions
        filter_conditions = []

        filter_conditions.concat(term_keys) if terms_keys_present?
        filter_conditions.concat(range_keys) if range_keys_present?

        filter_conditions
      end

      def filter_keys_present?
        range_keys_present? || terms_keys_present?
      end

      def terms_keys_present?
        TERM_KEYS.detect { |key, _| @params[key].present? }
      end

      def range_keys_present?
        RANGE_KEYS.detect { |key| @params[key].present? }
      end

      def term_keys
        TERM_KEYS.map do |term_key, search_key|
          next unless @params.key? term_key

          { term: { search_key => @params[term_key] } }
        end.compact
      end

      def range_keys
        RANGE_KEYS.map do |range_key|
          next unless @params.key? range_key

          { range: { range_key => @params[range_key] } }
        end.compact
      end
    end
  end
end
