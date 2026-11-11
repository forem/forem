module EdgeCache
  class BustOrganization
    def self.call(organization, slug)
      return unless organization && slug

      keys = organization.respond_to?(:record_key) ? [organization.record_key] : []
      fallback_paths = lambda do
        paths = ["/#{slug}"]
        paths.concat(organization.articles.pluck(:path)) if organization.respond_to?(:articles)
        paths
      end

      # Organization profile, custom domain, README, and published article responses all carry
      # the organization's surrogate key, so Fastly evicts them in one call without iterating
      # over every article path. Self-hosted Nginx/OpenResty resolves fallback_paths lazily.
      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
    end
  end
end
