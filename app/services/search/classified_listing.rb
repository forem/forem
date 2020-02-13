module Search
  class ClassifiedListing
    INDEX_NAME = "classified_listings_#{Rails.env}".freeze
    INDEX_ALIAS = "classified_listings_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/classified_listings.json"), symbolize_names: true).freeze

    class << self
      def index(classified_listing_id, serialized_data)
        SearchClient.index(
          id: classified_listing_id,
          index: INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def find_document(classified_listing_id)
        SearchClient.get(id: classified_listing_id, index: INDEX_ALIAS)
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
            number_of_shards: 2,
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
        MAPPINGS
      end
    end
  end
end
