module Search
  module QueryBuilders
    # Its descendants are used by Search::Base.search_documents to search for documents in the index
    class QueryBase
      attr_accessor :params, :body

      def as_hash
        @body
      end

      private

      def build_body
        @body = ActiveSupport::HashWithIndifferentAccess.new
        build_queries
        add_sort
        set_size
        add_highlight_fields
        filter_source
      end

      # Used to build boolean conditions for queries
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-bool-query.html
      def build_queries
        raise NotImplementedError
      end

      # Instructs the query builder to highlight fields
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/highlighting.html
      def add_highlight_fields; end

      # Uses source filtering to only return a subset of the source document
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/search-fields.html#source-filtering
      def filter_source; end

      # Determines which parameters are used for sorting
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/sort-search-results.html
      def add_sort
        sort_key = @params[:sort_by] || self.class::DEFAULT_PARAMS[:sort_by]
        sort_direction = @params[:sort_direction] || self.class::DEFAULT_PARAMS[:sort_direction]
        @body[:sort] = {
          sort_key => sort_direction
        }
      end

      # Determines how many documents to return in the search results
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/paginate-search-results.html
      def set_size
        # By default we will return 0 documents if size is not specified
        @body[:size] = @params[:size] || self.class::DEFAULT_PARAMS[:size]
      end

      def query_keys_present?
        self.class::QUERY_KEYS.detect { |key, _| @params[key].present? }
      end

      def query_conditions
        self.class::QUERY_KEYS.filter_map do |query_key, query_fields|
          next if @params[query_key].blank?

          fields = query_fields.presence || [query_key]

          query_hash(@params[query_key], fields)
        end
      end

      def match_phrase_conditions
        self.class::QUERY_KEYS.filter_map do |query_key, _fields|
          next if @params[query_key].blank?

          match_phrase(@params[query_key], query_key)
        end
      end

      # Builds the `match_prase` query
      # The match_phrase query analyzes the text and creates a phrase query out of the analyzed text.
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-match-query-phrase.html
      def match_phrase(phrase, query_key)
        {
          match_phrase: {
            query_key => { query: phrase, slop: 0 }
          }
        }
      end

      # Builds the `simple_query_string` query
      # This query uses a simple syntax to parse and split the provided query
      # string into terms based on special operators. The query then analyzes
      # each term independently before returning matching documents.
      # https://www.elastic.co/guide/en/elasticsearch/reference/7.10/query-dsl-simple-query-string-query.html
      def query_hash(key, fields)
        {
          simple_query_string: {
            query: "#{key}*", # `*` means prefix query
            fields: fields,
            lenient: true, # ignores format based errors
            analyze_wildcard: true # attempts to analyze wildcard terms in the query
          }
        }
      end
    end
  end
end
