module Search
  class User < Base
    SERIALIZER_CLASS = Search::UserSerializer
    INDEX_NAME = "users_#{Rails.env}".freeze
    INDEX_ALIAS = "users_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/users.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20

    class << self
      def search_documents(params:)
        set_query_size(params)
        query_hash = Search::QueryBuilders::User.new(params: params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits")
        paginated_results = paginate_hits(hits, params)

        paginated_results.map do |user_doc|
          prepare_doc(user_doc.dig("_source")).merge(metadata(results, params))
        end
      end

      private

      def prepare_doc(source)
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
          "positive_reactions_count" => source["positive_reactions_count"],
          "comments_count" => source["comments_count"],
          "badge_achievements_count" => source["badge_achievements_count"],
          "last_comment_at" => source["last_comment_at"],
          "roles" => source["roles"]
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
    end
  end
end
