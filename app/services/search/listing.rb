module Search
  class Listing < Base
    # We used to use both "classified listing" and "listing" throughout the app.
    # We standardized on the latter in most places, but kept the index name here.
    INDEX_NAME = "classified_listings_#{Rails.env}".freeze
    INDEX_ALIAS = "classified_listings_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/listings.json"), symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 75

    class << self
      private

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
    end
  end
end
