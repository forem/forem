module Search
  class Base
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
        SearchClient.delete(id: doc_id, index: self::INDEX_ALIAS)
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

      TRANSPORT_EXCEPTIONS = [
        Elasticsearch::Transport::Transport::Errors::BadRequest,
        Elasticsearch::Transport::Transport::Errors::NotFound,
      ].freeze

      def request
        yield
      rescue *TRANSPORT_EXCEPTIONS => e
        class_name = e.class.name.demodulize

        DatadogStatsClient.increment("elasticsearch.errors", tags: ["error:#{class_name}"], message: e.message)

        # raise specific error if known, generic one if unknown
        error_class = "::Search::Errors::Transport::#{class_name}".safe_constantize
        raise error_class, e.message if error_class

        raise ::Search::Errors::TransportError, e.message
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
