module Search
  module QueryBuilders
    class User < QueryBase
      QUERY_KEYS = %i[
        search_fields
      ].freeze

      # In the event we want to search for documents that do NOT contain certain values
      EXCLUDED_TERM_KEYS = {
        exclude_roles: "roles"
      }.freeze

      DEFAULT_PARAMS = {
        sort_by: "hotness_score",
        sort_direction: "desc",
        size: 0
      }.freeze

      def initialize(params:)
        super()

        @params = params.deep_symbolize_keys

        # default to excluding users who are suspended
        # TODO: [@jacobherrington] banned can be removed once the data scripts have succesfully run on all Forems
        @params[:exclude_roles] = %w[suspended banned]

        build_body
      end

      private

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
        @body[:query][:bool][:must_not] = excluded_term_keys if excluded_term_keys_present?
      end

      def excluded_term_keys_present?
        self.class::EXCLUDED_TERM_KEYS.detect { |key, _| @params[key].present? }
      end

      def excluded_term_keys
        EXCLUDED_TERM_KEYS.filter_map do |term_key, search_key|
          next unless @params.key? term_key

          { terms: { search_key => Array.wrap(@params[term_key]) } }
        end
      end
    end
  end
end
