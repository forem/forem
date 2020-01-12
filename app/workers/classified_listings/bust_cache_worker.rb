module ClassifiedListings
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(classified_listing_id)
      classified_listing = ClassifiedListing.find_by(id: classified_listing_id)
      return unless classified_listing

      CacheBuster.bust_classified_listings(classified_listing)
    end
  end
end
