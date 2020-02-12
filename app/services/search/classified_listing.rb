module Search
  class ClassifiedListing
    INDEX_NAME = "classified_listings_#{Rails.env}".freeze
    INDEX_ALIAS = "classified_listings_#{Rails.env}_alias".freeze

    class << self
      def index(classified_listing__id, serialized_data)
        SearchClient.index(
          id: classified_listing__id,
          index: INDEX_ALIAS,
          body: serialized_data,
        )
      end

      def find_document(classified_listing__id)
        SearchClient.get(id: classified_listing__id, index: INDEX_ALIAS)
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
        # "In Elasticsearch, there is no dedicated array datatype. Any field can
        # contain zero or more values by default, however, all values in the
        # array must be of the same datatype."
        #
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/array.html

        {
          dynamic: "strict",
          properties: {
            id: {
              type: "keyword"
            },
            author: {
              dynamic: "strict",
              # You don't have to specify type: "object" since it is the default.
              # Specifying type: "object" will break specs because when you later
              # call the mappings API on Elasticsearch, it will NOT return the
              # type: object key, value pair.
              #
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/object.html#object
              properties: {
                username: {
                  type: "keyword"
                },
                name: {
                  type: "keyword"
                },
                profile_image_90: {
                  type: "keyword"
                }
              }
            },
            bumped_at: {
              type: "date"
            },
            category: {
              type: "keyword"
            },
            contact_via_connect: {
              type: "boolean"
            },
            expires_at: {
              type: "date"
            },
            location: {
              type: "text",
              fields: {
                raw: {
                  type: "keyword"
                }
              }
            },
            processed_html: {
              type: "text"
            },
            slug: {
              type: "text",
              fields: {
                raw: {
                  type: "keyword"
                }
              }
            },
            tag_list: {
              # Think of this as an Array - see comment at the top of this method
              type: "keyword"
            },
            title: {
              type: "text",
              fields: {
                raw: {
                  type: "keyword"
                }
              }
            },
            user_id: {
              type: "keyword"
            }
          }
        }
      end
    end
  end
end
