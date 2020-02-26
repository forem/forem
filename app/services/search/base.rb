module Search
  class Base
    include Transport

    class << self
      def index(doc_id, serialized_data)
        request do
          SearchClient.index(
            id: doc_id,
            index: self::INDEX_ALIAS,
            body: serialized_data,
          )
        end
      end

      def find_document(doc_id)
        request do
          SearchClient.get(id: doc_id, index: self::INDEX_ALIAS)
        end
      end

      def delete_document(doc_id)
        request do
          SearchClient.delete(id: doc_id, index: self::INDEX_ALIAS)
        end
      end

      def create_index(index_name: self::INDEX_NAME)
        request do
          SearchClient.indices.create(index: index_name, body: settings)
        end
      end

      def delete_index(index_name: self::INDEX_NAME)
        request do
          SearchClient.indices.delete(index: index_name)
        end
      end

      def refresh_index(index_name: self::INDEX_ALIAS)
        request do
          SearchClient.indices.refresh(index: index_name)
        end
      end

      def add_alias(index_name: self::INDEX_NAME, index_alias: self::INDEX_ALIAS)
        request do
          SearchClient.indices.put_alias(index: index_name, name: index_alias)
        end
      end

      def update_mappings(index_alias: self::INDEX_ALIAS)
        request do
          SearchClient.indices.put_mapping(index: index_alias, body: self::MAPPINGS)
        end
      end

      private

      def settings
        { settings: { index: index_settings } }
      end

      def index_settings
        raise "Search classes must implement their own index settings"
      end
    end
  end
end
