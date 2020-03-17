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

      def set_query_size(params)
        params[:page] ||= self::DEFAULT_PAGE
        params[:per_page] ||= self::DEFAULT_PER_PAGE

        # pages start at 0
        params[:size] = params[:per_page].to_i * (params[:page].to_i + 1)
      end

      def paginate_hits(hits, params)
        start = params[:per_page] * params[:page]
        hits[start, params[:per_page]] || []
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
