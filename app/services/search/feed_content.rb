module Search
  class FeedContent < Base
    INDEX_NAME = "feed_content_#{Rails.env}".freeze
    INDEX_ALIAS = "feed_content_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/feed_content.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 60

    class << self
      def search_documents(params:)
        set_query_size(params)
        query_hash = Search::QueryBuilders::FeedContent.new(params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits").map do |feed_doc|
          prepare_doc(feed_doc)
        end
        paginate_hits(hits, params)
      end

      private

      def prepare_doc(hit)
        source = hit.dig("_source")
        source["tag_list"] = hit["tags"]&.map { |t| t["name"] } || []
        source["id"] = source["id"].split("_").last.to_i
        source["tag_list"] = source["tags"]&.map { |t| t["name"] } || []
        source["flare_tag"] = source["flare_tag_hash"]
        source["user_id"] = source.dig("user", "id")
        source["highlight"] = hit["highlight"]
        source["readable_publish_date"] = source["readable_publish_date_string"]

        source.merge(timestamps_hash(hit))
      end

      def timestamps_hash(hit)
        published_at = hit.dig("_source", "published_at")
        published_at_timestamp = Time.zone.parse(published_at || "")
        {
          "published_at_int" => published_at_timestamp.to_i,
          "published_timestamp" => published_at
        }
      end

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
    end
  end
end
