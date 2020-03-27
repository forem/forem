module Search
  module QueryBuilders
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

      def add_highlight_fields; end

      def filter_source; end

      def add_sort
        sort_key = @params[:sort_by] || self.class::DEFAULT_PARAMS[:sort_by]
        sort_direction = @params[:sort_direction] || self.class::DEFAULT_PARAMS[:sort_direction]
        @body[:sort] = {
          sort_key => sort_direction
        }
      end

      def set_size
        # By default we will return 0 documents if size is not specified
        @body[:size] = @params[:size] || self.class::DEFAULT_PARAMS[:size]
      end

      def query_keys_present?
        self.class::QUERY_KEYS.detect { |key, _| @params[key].present? }
      end

      def query_conditions
        self.class::QUERY_KEYS.map do |query_key, query_fields|
          next if @params[query_key].blank?

          fields = query_fields.presence || [query_key]

          {
            simple_query_string: {
              query: "#{@params[query_key]}*",
              fields: fields,
              lenient: true,
              analyze_wildcard: true
            }
          }
        end.compact
      end
    end
  end
end
