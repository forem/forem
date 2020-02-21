module Search
  class Base
    class << self
      def index(doc_id, serialized_data)
        SearchClient.index(
          id: doc_id,
          index: self::INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def find_document(doc_id)
        SearchClient.get(id: doc_id, index: self::INDEX_ALIAS)
      end

      def delete_document(doc_id)
        SearchClient.delete(id: doc_id, index: self::INDEX_ALIAS)
      end

      def create_index(index_name: self::INDEX_NAME)
        SearchClient.indices.create(index: index_name, body: settings)
      end

      def delete_index(index_name: self::INDEX_NAME)
        SearchClient.indices.delete(index: index_name)
      end

      def refresh_index(index_name: self::INDEX_ALIAS)
        SearchClient.indices.refresh(index: index_name)
      end

      def add_alias(index_name: self::INDEX_NAME, index_alias: self::INDEX_ALIAS)
        SearchClient.indices.put_alias(index: index_name, name: index_alias)
      end

      def update_mappings(index_alias: self::INDEX_ALIAS)
        SearchClient.indices.put_mapping(index: index_alias, body: self::MAPPINGS)
      end

      private

      def search(body:)
        SearchClient.search(index: self::INDEX_ALIAS, body: body)
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        ::DatadogStatsClient.increment(
          "elasticsearch.errors", tags: ["error:BadRequest", "index:#{self::INDEX_ALIAS}"]
        )
        empty_response
      end

      def empty_response
        { "hits" => { "total" => { "value" => 0 }, "hits" => [] } }
      end

      def settings
        { settings: { index: index_settings } }
      end

      def index_settings
        raise "Search classes must implement their own index settings"
      end
    end
  end
end
