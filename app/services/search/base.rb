module Search
  class Base
    class << self
      def index(doc_id, serialized_data)
        Search::Client.index(
          id: doc_id,
          index: self::INDEX_ALIAS,
          body: serialized_data.merge(last_indexed_at: Time.current),
        )
      end

      def bulk_index(data_hashes)
        indexing_hashes = data_hashes.map do |data_hash|
          model_hash = data_hash.with_indifferent_access
          model_hash[:last_indexed_at] = Time.current
          {
            index: {
              _index: self::INDEX_ALIAS,
              _id: model_hash[:id],
              data: model_hash
            }
          }
        end

        process_hashes(indexing_hashes)
      end

      def find_document(doc_id)
        Search::Client.get(id: doc_id, index: self::INDEX_ALIAS)
      end

      def delete_document(doc_id)
        Search::Client.delete(id: doc_id, index: self::INDEX_ALIAS)
      end

      def index_exists?(index_name: self::INDEX_NAME)
        Search::Client.indices.exists(index: index_name)
      end

      def create_index(index_name: self::INDEX_NAME)
        Search::Client.indices.create(index: index_name, body: settings)
      end

      def update_index(index_name: self::INDEX_NAME)
        return unless dynamic_index_settings.any?

        Search::Client.indices.put_settings(index: index_name, body: dynamic_settings)
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

      def document_count
        Search::Client.count(index: self::INDEX_ALIAS)["count"]
      end

      def search_documents(params:)
        set_query_size(params)
        query_hash = "Search::QueryBuilders::#{name.demodulize}".safe_constantize.new(params: params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits").map { |hit| prepare_doc(hit) }
        paginate_hits(hits, params)
      end

      private

      def prepare_doc(hit)
        hit["_source"]
      end

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

      def dynamic_settings
        { settings: { index: dynamic_index_settings } }
      end

      def dynamic_index_settings
        {}
      end

      def process_hashes(indexing_hashes)
        indexing_hashes.in_groups_of(1000, false).flat_map do |hashes|
          indexing_chunks(hashes).filter_map { |chunk| Search::Client.bulk(body: chunk) }
        end
      end

      def indexing_chunks(hashes)
        return [] unless hashes.any?
        return to_enum(__method__, hashes) unless block_given?

        size = 0
        chunk = []
        hashes.each do |hash|
          chunk << hash
          size += hash.to_s.bytesize
          next unless size > 5.megabytes

          yield chunk
          size = 0
          chunk = []
        end
        yield chunk
      end
    end
  end
end
