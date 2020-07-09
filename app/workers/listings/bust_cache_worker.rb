module Listings
  class BustCacheWorker < BustCacheBaseWorker
    def perform(listing_id)
      listing = Listing.find_by(id: listing_id)
      return unless listing

      CacheBuster.bust_listings(listing)
    end
  end
end
