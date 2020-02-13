module Search
  class Tag
    INDEX_NAME = "tags_#{Rails.env}".freeze
    INDEX_ALIAS = "tags_#{Rails.env}_alias".freeze
    MAPPING = JSON.parse(File.read("config/elasticsearch/mappings/tags.json"), symbolize_names: true).freeze

    class << self
      def index(tag_id, serialized_data)
        SearchClient.index(
          id: tag_id,
          index: INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def find_document(tag_id)
        SearchClient.get(id: tag_id, index: INDEX_ALIAS)
      end

      def create_index(index_name: INDEX_NAME)
        SearchClient.indices.create(index: index_name, body: settings)
      end

      def delete_index(index_name: INDEX_NAME)
        SearchClient.indices.delete(index: index_name)
      end

      def add_alias(index_name: INDEX_NAME, index_alias: INDEX_ALIAS)
        SearchClient.indices.put_alias(index: index_name, name: index_alias)
      end

      def update_mappings(index_alias: INDEX_ALIAS)
        SearchClient.indices.put_mapping(index: index_alias, body: mappings)
      end

      private

      def settings
        { settings: { index: index_settings } }
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

      def mappings
        MAPPING
      end
    end
  end
end
