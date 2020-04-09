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
        query_hash = Search::QueryBuilders::User.new(params).as_hash

        results = search(body: query_hash)
        hits = results.dig("hits", "hits")
        paginated_results = paginate_hits(hits, params)

        hits = paginated_results.map do |user_doc|
          prepare_doc(user_doc.dig("_source"))
        end

        {
          users: hits
        }.merge(metadata(results, params)).with_indifferent_access
      end

      private

      def prepare_doc(hit)
        SERIALIZER_CLASS.attributes_to_serialize.keys.reduce({}) do |m, k|
          m.merge(k.to_s => hit[k.to_s])
        end
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
