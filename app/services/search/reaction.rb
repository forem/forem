module Search
  class Reaction < Base
    INDEX_NAME = "reactions_#{Rails.env}".freeze
    INDEX_ALIAS = "reactions_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/reactions.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 80

    class << self
      private

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
