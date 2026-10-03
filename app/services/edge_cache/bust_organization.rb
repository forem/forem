module EdgeCache
  class BustOrganization
    def self.call(organization, slug)
      return unless organization && slug

      # Pages served on an org's custom domain (its root, readme pages) are tagged with the
      # org's surrogate key. URL purges can't reach them: the Fastly purge API can't resolve
      # custom domains attached through Domain Management to our service.
      EdgeCache::PurgeByKey.call(organization.record_key) if organization.respond_to?(:record_key)

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
