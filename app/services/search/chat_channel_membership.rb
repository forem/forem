module Search
  class ChatChannelMembership < Base
    INDEX_NAME = "chat_channel_memberships_#{Rails.env}".freeze
    INDEX_ALIAS = "chat_channel_memberships_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/chat_channel_memberships.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 30

    class << self
      def search_documents(params:, user_id:)
        set_query_size(params)
        query_hash = Search::QueryBuilders::ChatChannelMembership.new(params, user_id).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits").map { |ccm_doc| ccm_doc.dig("_source") }
        paginate_hits(hits, params)
      end

      private

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 3,
            number_of_replicas: 1
          }
        else
          {
            number_of_shards: 1,
            number_of_replicas: 0
          }
        end
      end
    end
  end
end
