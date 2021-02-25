module EdgeCache
  class BustOrganization
    def self.call(organization, slug)
      return unless organization && slug

      cache_bust = EdgeCache::Bust.new

      cache_bust.call("/#{slug}")

      begin
        organization.articles.find_each do |article|
          cache_bust.call(article.path)
        end
      rescue StandardError => e
        Rails.logger.error("Tag issue: #{e}")
      end
    end
  end
end
