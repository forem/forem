module DataUpdateScripts
  class ReIndexListingWithOriginallyPublishedAt
    def run
      Listing.find_each(&:index_to_elasticsearch_inline)
    end
  end
end
