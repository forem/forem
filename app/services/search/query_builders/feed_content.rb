module Search
  module QueryBuilders
    class FeedContent < QueryBase
      # In order for highlighting to work properly we have to search the fields we want to highlight
      QUERY_KEYS = {
        search_fields: [
          "tags.keywords_for_search",
          "tags.name^3",
          "body_text^2",
          "title^6",
          "user.name",
          "user.username",
          "organization.name",
        ]
      }.freeze

      # Search keys from our controllers may not match what we have stored in Elasticsearch so we map them here,
      # this allows us to change our Elasticsearch docs without worrying about the frontend
      TERM_KEYS = {
        id: "id", # NOTE: FeedContent ids are formatted article_#, podcast_episode_#, comment_#
        tag_names: "tags.name",
        approved: "approved",
        user_id: "user.id",
        class_name: "class_name",
        published: "published",
        organization_id: "organization.id"
      }.freeze

      RANGE_KEYS = %i[
        published_at
      ].freeze

      DEFAULT_PARAMS = {
        sort: [
          :_score,
          { score: "desc" },
          { hotness_score: "desc" },
          { comments_count: "desc" },
        ],
        size: 0
      }.freeze

      HIGHLIGHT_FIELDS = %w[
        body_text
      ].freeze

      SOURCE = %i[
        id
        class_name
        cloudinary_video_url
        comments_count
        flare_tag_hash
        main_image
        path
        public_reactions_count
        published_at
        readable_publish_date_string
        reading_time
        slug
        tags
        title
        video_duration_in_minutes
        video_duration_string
        user
        organization
      ].freeze

      attr_accessor :params, :body

      def initialize(params:)
        super()

        @params = params.deep_symbolize_keys

        # Default to only showing published articles to start
        @params[:published] = true

        build_body
        add_function_scoring unless sort_params_present?
      end

      private

      def add_sort
        return @body[:sort] = DEFAULT_PARAMS[:sort] unless sort_params_present?

        @body[:sort] = { @params[:sort_by] => @params[:sort_direction] }
      end

      def add_highlight_fields
        highlight_fields = { encoder: "html", pre_tags: "<mark>", post_tags: "</mark>", fields: {} }
        HIGHLIGHT_FIELDS.each do |field_name|
          # This hash can be filled with options to further customize our highlighting
          # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html#request-body-search-highlighting
          highlight_fields[:fields][field_name] = { order: :score, number_of_fragments: 2, fragment_size: 75 }
        end
        @body[:highlight] = highlight_fields
      end

      def filter_source
        @body[:_source] = SOURCE
      end

      def build_queries
        @body[:query] = { bool: {} }
        @body[:query][:bool][:filter] = filter_conditions if filter_keys_present?
        return unless query_keys_present?

        @body[:query][:bool][:must] = query_conditions
        # Boost the score of queries that match these conditions but if they dont match any,
        # minimum_should_match: 0, then that is OK
        @body[:query][:bool][:should] = match_phrase_conditions
        @body[:query][:bool][:minimum_should_match] = 0
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
        TERM_KEYS.filter_map do |term_key, search_key|
          next unless @params.key? term_key

          { terms: { search_key => Array.wrap(@params[term_key]) } }
        end
      end

      def range_keys
        RANGE_KEYS.filter_map do |range_key|
          next unless @params.key? range_key

          { range: { range_key => @params[range_key] } }
        end
      end

      def query_hash(key, fields)
        {
          simple_query_string: {
            query: key.downcase,
            fields: fields,
            lenient: true,
            analyze_wildcard: true,
            minimum_should_match: 2
          }
        }
      end

      def add_function_scoring
        @body[:query] = { function_score: { query: @body[:query] } }
        @body[:query][:function_score][:functions] = scoring_functions
      end

      def scoring_functions
        [
          scoring_filter(1000, 2.5),
          scoring_filter(500, 2),
          scoring_filter(100, 1.5),
        ]
      end

      def scoring_filter(score, weight)
        {
          filter: {
            range: {
              score: {
                gte: score
              }
            }
          },
          weight: weight
        }
      end

      def sort_params_present?
        @params[:sort_by] && @params[:sort_direction]
      end
    end
  end
end
