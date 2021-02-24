module EdgeCache
  class BustListings < Buster
    def self.call(listing)
      return unless listing

      # we purge all listings as it's the wanted behavior with the following URL purging
      listing.purge_all

      buster = EdgeCache::Buster.new
      buster.bust("/listings")
      buster.bust("/listings?i=i")
      buster.bust("/listings/#{listing.category}/#{listing.slug}")
      buster.bust("/listings/#{listing.category}/#{listing.slug}?i=i")
      buster.bust("/listings/#{listing.category}")
    end
  end
end
