module ClassifiedListings
  class UnpublishExpiredListingsJob < ApplicationJob
    queue_as :classified_listings_unpublish_expired

    def perform
      expired_listings = ClassifiedListing.where(published: true).where(expire_on: Date.today)
      return if expired_listings.empty?

      expired_listings.each do |listing|
        listing.published = false
        listing.save
      end
    end
  end
end
