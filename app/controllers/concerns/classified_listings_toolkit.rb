module ClassifiedListingsToolkit
  extend ActiveSupport::Concern

  def clear_listings_cache
    CacheBuster.new.bust("/listings")
    CacheBuster.new.bust("/listings?i=i")
    CacheBuster.new.bust("/listings/#{@classified_listing.category}/#{@classified_listing.slug}")
    CacheBuster.new.bust("/listings/#{@classified_listing.category}/#{@classified_listing.slug}?i=i")
  end

  def potato
    puts "!!!!!!!!!!!!!!!!!!"
  end
end