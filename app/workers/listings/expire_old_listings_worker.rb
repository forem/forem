module Listings
  class ExpireOldListingsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 5

    def perform
      Listing.published.where("bumped_at < ?", 30.days.ago).each do |listing|
        listing.update(published: false)
      end
      Listing.published.where("expires_at < ?", Time.zone.today).each do |listing|
        listing.update(published: false)
      end
    end
  end
end
