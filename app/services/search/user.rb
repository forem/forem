module Search
  class User < Base
    INDEX_NAME = "users_#{Rails.env}".freeze
    INDEX_ALIAS = "users_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/users.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 20

    class << self
      def search_documents(params:)
        set_query_size(params)
        query_hash = Search::QueryBuilders::User.new(params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits").map do |user_doc|
          prepare_doc(user_doc.dig("_source"))
        end
        paginate_hits(hits, params)
      end

      private

      def prepare_doc(hit)
        {
          "user" => {
            "username" => hit["username"],
            "name" => hit["username"],
            "profile_image_90" => hit["profile_image_90"]
          },
          "title" => hit["name"],
          "path" => hit["path"],
          "id" => hit["id"]
        }
      end

      def set_query_size(params)
        params[:page] ||= DEFAULT_PAGE
        params[:per_page] ||= DEFAULT_PER_PAGE

        # pages start at 0
        params[:size] = params[:per_page].to_i * (params[:page].to_i + 1)
      end

      def paginate_hits(hits, params)
        start = params[:per_page] * params[:page]
        hits[start, params[:per_page]] || []
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
