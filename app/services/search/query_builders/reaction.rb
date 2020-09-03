module Search
  module QueryBuilders
    class Reaction < QueryBase
      QUERY_KEYS = {
        search_fields: [
          "reactable.tags.keywords_for_search",
          "reactable.tags.name^3",
          "reactable.body_text^2",
          "reactable.title^6",
          "reactable.user.name",
          "reactable.user.username",
        ]
      }.freeze

      # Search keys from our controllers may not match what we have stored in Elasticsearch so we map them here,
      # this allows us to change our Elasticsearch docs without worrying about the frontend
      TERM_KEYS = {
        category: "category",
        tag_names: "reactable.tags.name",
        user_id: "user_id",
        status: "status"
      }.freeze

      DEFAULT_PARAMS = {
        sort_by: "created_at",
        sort_direction: "desc",
        size: 0
      }.freeze

      SOURCE = %i[
        id
        reactable.path
        reactable.published_date_string
        reactable.reading_time
        reactable.tags
        reactable.title
        reactable.user
      ].freeze

      attr_accessor :params, :body

      def initialize(params:)
        super()

        @params = params.deep_symbolize_keys

        # Default to only readinglist reactions
        @params[:category] = "readinglist"

        build_body
      end

      private

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:filter] = terms_keys if terms_keys_present?
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end

      def terms_keys_present?
        TERM_KEYS.detect { |key, _| @params[key].present? }
      end

      def terms_keys
        TERM_KEYS.flat_map do |term_key, search_key|
          next unless @params.key? term_key

          values = Array.wrap(@params[term_key])

          if params[:tag_boolean_mode] == "all" && term_key == :tag_names
            values.map { |val| { term: { search_key => val } } }
          else
            { terms: { search_key => values } }
          end
        end.compact
      end

      def query_hash(key, fields)
        {
          simple_query_string: {
            query: key,
            fields: fields,
            lenient: true,
            analyze_wildcard: true,
            minimum_should_match: 2
          }
        }
      end
    end
  end
end
