module Search
  class Base
    class << self
      def index(doc_id, serialized_data)
        Search::Client.index(
          id: doc_id,
          index: self::INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def find_document(doc_id)
        Search::Client.get(id: doc_id, index: self::INDEX_ALIAS)
      end

      def delete_document(doc_id)
        Search::Client.delete(id: doc_id, index: self::INDEX_ALIAS)
      end

      def create_index(index_name: self::INDEX_NAME)
        Search::Client.indices.create(index: index_name, body: settings)
      end

      def delete_index(index_name: self::INDEX_NAME)
        Search::Client.indices.delete(index: index_name)
      end

      def refresh_index(index_name: self::INDEX_ALIAS)
        Search::Client.indices.refresh(index: index_name)
      end

      def add_alias(index_name: self::INDEX_NAME, index_alias: self::INDEX_ALIAS)
        Search::Client.indices.put_alias(index: index_name, name: index_alias)
      end

      def update_mappings(index_alias: self::INDEX_ALIAS)
        Search::Client.indices.put_mapping(index: index_alias, body: self::MAPPINGS)
      end

      private

      def search(body:)
        Search::Client.search(index: self::INDEX_ALIAS, body: body)
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
