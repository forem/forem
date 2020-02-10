module Search
  class Tag
    INDEX_NAME = "tags_#{Rails.env}".freeze
    INDEX_ALIAS = "tags_#{Rails.env}_alias".freeze

    class << self
      def index(tag_id, serialized_data)
        SearchClient.index(
          id: tag_id,
          index: INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def get(tag_id)
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
        {
          dynamic: "strict",
          properties: {
            id: {
              type: "keyword"
            },
            name: {
              type: "text",
              fields: {
                raw: {
                  type: "keyword"
                }
              }
            },
            hotness_score: {
              type: "integer"
            },
            supported: {
              type: "boolean"
            },
            short_summary: {
              type: "text"
            }
          }
        }
      end
    end
  end
end
