module Search
  module QueryBuilders
    class User < QueryBase
      QUERY_KEYS = %i[
        search_fields
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "hotness_score",
        sort_direction: "desc",
        size: 0
      }.freeze

      def initialize(params)
        @params = params.deep_symbolize_keys
        build_body
      end

      private

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end
    end
  end
end
