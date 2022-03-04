module EdgeCache
  class BustListings
    def self.call(listing)
      return unless listing

      # we purge all listings as it's the wanted behavior with the following URL purging
      listing.purge_all

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/listings")
      cache_bust.call("/listings?i=i")
      cache_bust.call("/listings/#{listing.category}/#{listing.slug}")
      cache_bust.call("/listings/#{listing.category}/#{listing.slug}?i=i")
      cache_bust.call("/listings/#{listing.category}")
    end
  end
end
