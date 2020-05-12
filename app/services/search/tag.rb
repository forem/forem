module Search
  class Tag < Base
    INDEX_NAME = "tags_#{Rails.env}".freeze
    INDEX_ALIAS = "tags_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/tags.json"), symbolize_names: true).freeze

    class << self
      def search_documents(query_string)
        results = search(body: query(query_string))
        results.dig("hits", "hits").map { |tag_doc| tag_doc.dig("_source") }
      end

      private

      def query(query_string)
        {
          query: {
            query_string: {
              query: query_string,
              analyze_wildcard: true,
              allow_leading_wildcard: false
            }
          },
          sort: {
            hotness_score: "desc"
          }
        }
      end

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 1,
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
