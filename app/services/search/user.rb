module Search
  class User < Base
    INDEX_NAME = "users_#{Rails.env}".freeze
    INDEX_ALIAS = "users_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/users.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 20

    class << self
      def search_usernames(username)
        results = search(body: username_query(username))
        results.dig("hits", "hits").map do |doc|
          source = doc["_source"]
          {
            "username" => source["username"],
            "name" => source["name"],
            "profile_image_90" => source["profile_image_90"]
          }
        end
      end

      private

      def username_query(username)
        {
          query: {
            query_string: {
              query: "username:#{username}*",
              analyze_wildcard: true,
              allow_leading_wildcard: false
            }
          }
        }
      end

      def prepare_doc(hit)
        source = hit["_source"]
        {
          "user" => {
            "username" => source["username"],
            "name" => source["username"],
            "profile_image_90" => source["profile_image_90"]
          },
          "title" => source["name"],
          "path" => source["path"],
          "id" => source["id"],
          "class_name" => "User",
          "public_reactions_count" => source["public_reactions_count"],
          "comments_count" => source["comments_count"],
          "badge_achievements_count" => source["badge_achievements_count"],
          "last_comment_at" => source["last_comment_at"],
          "user_id" => source["id"]
        }
      end

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 10,
            number_of_replicas: 1
          }
        else
          {
            number_of_shards: 1,
            number_of_replicas: 0
          }
        end
      end

      def dynamic_index_settings
        if Rails.env.production?
          { refresh_interval: "10s" }
        else
          { refresh_interval: "1s" }
        end
      end
    end
  end
end
