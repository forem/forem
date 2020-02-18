module Search
  class ClassifiedListingEsIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(classified_listing_id)
      classified_listing = ::ClassifiedListing.find(classified_listing_id)
      classified_listing.index_to_elasticsearch_inline
    end
  end
end
