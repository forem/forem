module EdgeCache
  class BustListings < Bust
    def self.call(listing)
      return unless listing

      # we purge all listings as it's the wanted behavior with the following URL purging
      listing.purge_all

      bust("/listings")
      bust("/listings?i=i")
      bust("/listings/#{listing.category}/#{listing.slug}")
      bust("/listings/#{listing.category}/#{listing.slug}?i=i")
      bust("/listings/#{listing.category}")
    end
  end
end
