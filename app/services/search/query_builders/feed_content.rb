module Search
  module QueryBuilders
    class FeedContent < QueryBase
      # In order for highlighting to work properly we have to search the fields we want to highlight
      QUERY_KEYS = {
        search_fields: [
          "tags.*",
          "body_text",
          "title",
          "user.name",
          "user.username",
          "organization.name",
        ]
      }.freeze

      # Search keys from our controllers may not match what we have stored in Elasticsearch so we map them here,
      # this allows us to change our Elasticsearch docs without worrying about the frontend
      TERM_KEYS = {
        tag_names: "tags.name",
        approved: "approved",
        user_id: "user.id",
        class_name: "class_name",
        published: "published"
      }.freeze

      RANGE_KEYS = %i[
        published_at
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "hotness_score",
        sort_direction: "desc",
        size: 0
      }.freeze

      HIGHLIGHT_FIELDS = %w[
        body_text
      ].freeze

      attr_accessor :params, :body

      def initialize(params)
        @params = params.deep_symbolize_keys

        # Default to only showing published articles to start
        @params[:published] = true

        build_body
      end

      private

      def add_highlight_fields
        highlight_fields = { fields: {} }
        HIGHLIGHT_FIELDS.each do |field_name|
          # This hash can be filled with options to further customize our highlighting
          # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html#request-body-search-highlighting
          highlight_fields[:fields][field_name] = { order: :score, number_of_fragments: 2, fragment_size: 75 }
        end
        @body[:highlight] = highlight_fields
      end

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

          { terms: { search_key => Array.wrap(@params[term_key]) } }
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
