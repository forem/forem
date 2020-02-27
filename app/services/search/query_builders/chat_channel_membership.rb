module Search
  module QueryBuilders
    class ChatChannelMembership
      FILTER_KEYS = %i[
        channel_status
        channel_type
        status
        viewable_by
      ].freeze

      QUERY_KEYS = %i[
        channel_text
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "channel_last_message_at",
        sort_direction: "desc",
        size: 0
      }.freeze

      attr_accessor :params, :body

      def initialize(params, user_id)
        @params = params.deep_symbolize_keys
        @params[:viewable_by] = user_id

        # TODO: @mstruve: When we want to allow people like admins to
        # search ALL memberships this will need to change
        @params[:status] = "active"

        build_body
      end

      def as_hash
        @body
      end

      private

      def build_body
        @body = ActiveSupport::HashWithIndifferentAccess.new
        build_queries
        add_sort
        set_size
      end

      def build_queries
        @body[:query] = {}
        @body[:query][:bool] = { filter: filter_conditions }
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end

      def add_sort
        sort_key = @params[:sort_by] || DEFAULT_PARAMS[:sort_by]
        sort_direction = @params[:sort_direction] || DEFAULT_PARAMS[:sort_direction]
        @body[:sort] = {
          sort_key => sort_direction
        }
      end

      def set_size
        # By default we will return 0 documents if size is not specified
        @body[:size] = @params[:size] || DEFAULT_PARAMS[:size]
      end

      def filter_conditions
        FILTER_KEYS.map do |filter_key|
          next if @params[filter_key].blank? || @params[filter_key] == "all"

          { term: { filter_key => @params[filter_key] } }
        end.compact
      end

      def query_keys_present?
        QUERY_KEYS.detect { |key| @params[key].present? }
      end

      def query_conditions
        QUERY_KEYS.map do |query_key|
          next if @params[query_key].blank?

          {
            simple_query_string: {
              query: "#{@params[query_key]}*",
              fields: [query_key],
              lenient: true,
              analyze_wildcard: true
            }
          }
        end.compact
      end
    end
  end
end
