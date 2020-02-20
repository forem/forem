module Search
  class ClassifiedListingEsSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(classified_listing_id)
      classified_listing = ::ClassifiedListing.find_by(id: classified_listing_id)

      if classified_listing
        classified_listing.index_to_elasticsearch_inline
      else
        Search::ClassifiedListing.delete_document(classified_listing_id)
      end
    end
  end
end
