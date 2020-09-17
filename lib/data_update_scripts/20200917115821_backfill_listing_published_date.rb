module DataUpdateScripts
  class BackfillListingPublishedDate
    def run
      return unless Listing.column_names.include?("originally_published_at")

      Listing.find_each do |listing|
        if listing.published
          listing.update!(originally_published_at: listing.created_at)
        end
      end
    end
  end
end
