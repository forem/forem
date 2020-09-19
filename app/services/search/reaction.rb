module Search
  class Reaction < Base
    INDEX_NAME = "reactions_#{Rails.env}".freeze
    INDEX_ALIAS = "reactions_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/reactions.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 80

    class << self
      def search_documents(params:)
        set_query_size(params)
        query_hash = "Search::QueryBuilders::#{name.demodulize}".safe_constantize.new(params: params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits").map { |hit| prepare_doc(hit) }
        {
          "reactions" => paginate_hits(hits, params),
          "total" => results.dig("hits", "total", "value")
        }
      end

      private

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 10,
            number_of_replicas: 1
          }
        else
          {
            number_of_shards: 1,
            number_of_replicas: 0
          }
        end
      end

      def dynamic_index_settings
        if Rails.env.production?
          { refresh_interval: "2s" }
        else
          { refresh_interval: "1s" }
        end
      end
    end
  end
end
