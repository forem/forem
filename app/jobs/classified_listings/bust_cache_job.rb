module ClassifiedListings
  class BustCacheJob < ApplicationJob
    queue_as :classified_listings_bust_cache

    def perform(classified_listing_id, cache_buster = CacheBuster.new)
      classified_listing = ClassifiedListing.find_by(id: classified_listing_id)

      return unless classified_listing

      cache_buster.bust_classified_listings(classified_listing)
    end
  end
end
