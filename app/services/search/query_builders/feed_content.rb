module Search
  module QueryBuilders
    class FeedContent < QueryBase
      # In order for highlighting to work properly we have to search the fields we want to highlight
      QUERY_KEYS = {
        search_fields: [
          "tags.keywords_for_search",
          "tags.name^3", # boost tag names by a factor of 3
          "body_text^2", # boost body text by a factor of 2
          "title^6", # boost title by a factor of 6
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
          :_score, # internal score given by ES for each returned document
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

      # Highlights search results in HTML using `<mark>` returning 2 fragments on 75 chars each ordering them by score
      def add_highlight_fields
        highlight_fields = { encoder: "html", pre_tags: "<mark>", post_tags: "</mark>", fields: {} }
        HIGHLIGHT_FIELDS.each do |field_name|
          highlight_fields[:fields][field_name] = { order: :score, number_of_fragments: 2, fragment_size: 75 }
        end
        @body[:highlight] = highlight_fields
      end

      def filter_source
        @body[:_source] = SOURCE
      end

      def build_queries
        @body[:query] = { bool: {} }

        # The `filter` clause must appear in the matching document but it does not affect scoring
        @body[:query][:bool][:filter] = filter_conditions if filter_keys_present?
        return unless query_keys_present?

        # The `must` clause *must* appear in the matching document and it contributes to scoring
        @body[:query][:bool][:must] = query_conditions

        # Boost the score of queries that match these conditions but if they dont match any,
        # minimum_should_match: 0, then that is OK
        # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-bool-query.html#bool-min-should-match
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

          values = Array.wrap(@params[term_key])

          if params[:tag_boolean_mode] == "all" && term_key == :tag_names
            values.map { |val| { term: { search_key => val } } }
          else
            { terms: { search_key => values } }
          end
        end.compact
      end

      # Search fields based on a range
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-range-query.html
      def range_keys
        RANGE_KEYS.filter_map do |range_key|
          next unless @params.key? range_key

          { range: { range_key => @params[range_key] } }
        end
      end

      # Builds the `simple_query_string` query
      # This query uses a simple syntax to parse and split the provided query
      # string into terms based on special operators. The query then analyzes
      # each term independently before returning matching documents.
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-simple-query-string-query.html
      def query_hash(key, fields)
        {
          simple_query_string: {
            query: key.downcase,
            fields: fields,
            lenient: true, # ignores format based errors
            analyze_wildcard: true, # attempts to analyze wildcard terms in the query
            minimum_should_match: 2 # at least two clauses must match for a document to be returned
          }
        }
      end

      # Function scoring allows us to modify the score of the retrieved documents.
      # In this instance we're going to use the `weight` function as a multiplying factor
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-function-score-query.html#function-weight
      def add_function_scoring
        @body[:query] = { function_score: { query: @body[:query] } }
        @body[:query][:function_score][:functions] = scoring_functions
      end

      def scoring_functions
        [
          scoring_filter(1000, 2.5), # for results with a score greater than 1000, boost by 2.5x
          scoring_filter(500, 2), # for results with a score greater than 500, boost by 2x
          scoring_filter(100, 1.5), # for results with a score greater than 100, boost by 1.5x
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
